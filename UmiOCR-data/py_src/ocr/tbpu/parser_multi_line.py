# 排版解析-多栏-单行

from .tbpu import Tbpu
from .parser_tools.line_preprocessing import linePreprocessing  # 行预处理
from .parser_tools.gap_tree import GapTree  # 间隙树排序算法
from .parser_tools.table_layout import tryTableLayout  # 表格版面检测

class MultiLine(Tbpu):
    def __init__(self):
        self.tbpuName = "排版解析-多栏-单行"

        # 构建算法对象，指定包围盒的元素位置
        self.gtree = GapTree(lambda tb: tb["normalized_bbox"])

    def run(self, textBlocks):
        textBlocks = linePreprocessing(textBlocks)  # 预处理
        # 表格版面检测：命中则按行序输出（行内空格连接、行尾换行），跳过间隙树
        table = tryTableLayout(textBlocks)
        if table is not None:
            return table
        textBlocks = self.gtree.sort(textBlocks)  # 构建间隙树
        # 补充行尾间隔符
        for tb in textBlocks:
            tb["end"] = "\n"
            del tb["normalized_bbox"]
        return textBlocks
