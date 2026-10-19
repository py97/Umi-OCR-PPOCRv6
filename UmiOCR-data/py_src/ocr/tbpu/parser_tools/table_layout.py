# =========================================
# =============== 表格版面检测 =============
# =========================================
# 背景：GapTree 间隙树算法面向"多栏文章"设计——当页面存在贯穿整页的竖向
# 空白切线时，按"先左栏、后右栏"的前序遍历输出。这对报纸式分栏是正确的
# 阅读顺序；但对表格类版面（每行由多个单元格组成，人眼按行阅读），会输出成
# "先第一整列、再第二整列……"，与直觉相反。
#
# 本模块检测表格型版面；命中时按"行"输出（从上到下，行内从左到右），
# 行内单元格以空格连接、行尾换行；未命中返回 None，交回 GapTree 处理。
#
# 判定特征（全部满足才视为表格）：
#   1. 行数 ≥ MIN_ROWS，且"多块行"（含≥2个文块的行）占比 ≥ MULTI_ROW_RATIO；
#   2. 存在贯穿大多数行的竖向空白切线（列间隙）；
#   3. 多块行中 ≥ MULTI_CELLS_RATIO 的行占据 ≥2 个列区间；
#   4. 单元格平均填充率 < MAX_FILL_RATIO——表格单元格短、不填满列宽，
#      而文章分栏的段落行会填满所在栏（中文两端对齐尤甚），以此区分表格与分栏文章。

try:
    from umi_log import logger
except ImportError:  # 独立测试时允许无日志环境
    logger = None

MIN_ROWS = 3  # 最少行数
MULTI_ROW_RATIO = 0.6  # "多块行"占全部行的比例下限
CUT_SPAN_RATIO = 0.7  # 竖切线需贯穿的行比例下限
MULTI_CELLS_RATIO = 0.7  # 多块行中占据≥2个列区间的比例下限
MAX_FILL_RATIO = 0.8  # 单元格平均填充率上限（≥此值视为文章分栏）
MIN_CUT_WIDTH = 5.0  # 竖切线最小宽度，过滤页面边缘的发丝级间隙


def _log(msg):
    if logger:
        logger.info(f"[表格版面] {msg}")
    else:
        print(f"[表格版面] {msg}")


# 将封装单元 ((x0,y0,x1,y1), tb) 按垂直重叠分组为行，行内按 x0 从左到右
def _groupRows(units):
    rows = []
    i, n = 0, len(units)
    while i < n:
        bottom = units[i][0][3]
        row = [units[i]]
        j = i + 1
        while j < n and units[j][0][1] <= bottom:
            if units[j][0][3] > bottom:
                bottom = units[j][0][3]
            row.append(units[j])
            j += 1
        row.sort(key=lambda u: u[0][0])
        rows.append(row)
        i = j
    return rows


# 求一行内的水平间隙 [ (左, 右) ]
def _rowGaps(row, page_l, page_r):
    gaps = []
    search = page_l
    for u in row:
        l, r = u[0][0], u[0][2]
        if l > search:
            gaps.append((search, l))
        if r > search:
            search = r
    gaps.append((search, page_r))
    return gaps


# 逐行求间隙交集，得到贯穿性竖切线 [(left, right, start行号, end行号)]
def _computeCuts(rows, multi_indexes, page_l, page_r):
    cuts, gaps = [], []  # gaps: (l, r, 起始行号)
    last_idx = None
    for idx in multi_indexes:
        row_gaps = _rowGaps(rows[idx], page_l, page_r)
        merged = []
        used = [False] * len(row_gaps)
        for (l1, r1, s1) in gaps:
            best = None
            for k, (l2, r2) in enumerate(row_gaps):
                il, ir = max(l1, l2), min(r1, r2)
                if il <= ir:
                    if best is None or ir - il > best[1] - best[0]:
                        best = (il, ir, s1)
                    used[k] = True
            if best:
                merged.append(best)
            else:  # 间隙被打断，结算为切线
                cuts.append((l1, r1, s1, last_idx))
        for k, f in enumerate(used):
            if not f:  # 新出现的间隙
                merged.append((*row_gaps[k], idx))
        gaps = merged
        last_idx = idx
    for (l, r, s) in gaps:  # 收尾：延伸到最后一行的切线
        cuts.append((l, r, s, last_idx))
    return cuts


def _columnOf(cx, mids):
    for i, m in enumerate(mids):
        if cx < m:
            return i
    return len(mids)


# 检测表格版面。命中：返回按行排序、已设置end、已清理bbox的文块列表；未命中：None
def tryTableLayout(textBlocks):
    if len(textBlocks) < 4:
        return None
    units = [(tb["normalized_bbox"], tb) for tb in textBlocks]
    page_l = min(u[0][0] for u in units) - 1
    page_r = max(u[0][2] for u in units) + 1
    units.sort(key=lambda u: u[0][1])
    rows = _groupRows(units)
    if len(rows) < MIN_ROWS:
        return None
    multi_indexes = [i for i, r in enumerate(rows) if len(r) >= 2]
    if len(multi_indexes) < MULTI_ROW_RATIO * len(rows):
        return None
    # 贯穿性竖切线
    cuts = _computeCuts(rows, multi_indexes, page_l, page_r)
    kept = [
        c
        for c in cuts
        if c[1] - c[0] >= MIN_CUT_WIDTH and (c[3] - c[2] + 1) >= CUT_SPAN_RATIO * len(rows)
    ]
    if not kept:
        return None
    kept.sort(key=lambda c: c[0])
    mids = [(c[0] + c[1]) / 2 for c in kept]
    # 列占据与填充率检查
    multi_cells = 0
    fills = []
    for i in multi_indexes:
        cols = set()
        for (x0, y0, x1, y1), tb in rows[i]:
            ci = _columnOf((x0 + x1) / 2, mids)
            cols.add(ci)
            left = page_l if ci == 0 else mids[ci - 1]
            right = page_r if ci == len(mids) else mids[ci]
            # 跨列的合并单元格不参与填充率统计
            if x0 > left and x1 < right and right > left:
                fills.append((x1 - x0) / (right - left))
        if len(cols) >= 2:
            multi_cells += 1
    if multi_cells < MULTI_CELLS_RATIO * len(multi_indexes):
        return None
    if fills and sum(fills) / len(fills) >= MAX_FILL_RATIO:
        return None
    # ===== 命中表格：按行输出 =====
    _log(f"检测到表格版面（{len(rows)}行 / {len(kept)}条列切线），按行序输出")
    result = []
    for row in rows:
        last = len(row) - 1
        for k, (_, tb) in enumerate(row):
            tb["end"] = "\n" if k == last else " "
            del tb["normalized_bbox"]
            result.append(tb)
    return result
