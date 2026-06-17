from pathlib import Path

from docx import Document
from docx.shared import Pt
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "competition"
PDF_PATH = OUT_DIR / "MoonModGuard项目申报书.pdf"
DOCX_PATH = OUT_DIR / "MoonModGuard项目申报书.docx"

TITLE = "MoonModGuard 项目申报书"
PROJECT_NAME = "MoonModGuard：MoonBit 项目清单与供应链策略审计器"

SECTIONS = [
    (
        "一、项目简介",
        "MoonModGuard 是一个面向 MoonBit 生态的项目清单与供应链策略审计工具。项目解析 moon.mod、moon.pkg 等清单文本，提取模块元数据、包级依赖、导入别名和发布信息，构建项目快照，并根据策略输出元数据完整性、许可证合规性、依赖重复和未知依赖等诊断结果。",
    ),
    (
        "二、方向与场景",
        "随着 MoonBit 包生态持续增长，项目是否可发布、可复现、可维护，越来越依赖清单元数据和依赖声明质量。MoonModGuard 将这些工程要求转化为可测试的审计规则，可用于包发布前检查、竞赛仓库验收、课程项目规范检查，以及后续 CI 和包仓库审计。",
    ),
    (
        "三、核心功能",
        "项目实现 moon.mod 标量字段解析、数组字段解析、moon.mod 与 moon.pkg import 依赖解析、项目模型构建、默认策略评估和 Markdown 报告输出。默认策略检查缺失 README、缺失 repository、缺失 license、非 allowlist 许可证、未知依赖前缀和重复依赖。",
    ),
    (
        "四、原创性说明",
        "本项目为原创项目，不移植已有开源项目。项目聚焦 MoonBit 自身工程元数据和包供应链策略审计，不与常见格式解析、通用数据结构、内容寻址、解释执行或差异算法方向重合。首版不引入外部依赖，优先形成可复用的审计内核。",
    ),
    (
        "五、技术路线",
        "系统采用轻量扫描器解析清单文本，生成 ModuleManifest、PackageManifest 和 ProjectModel。策略评估器基于 Policy 输出 AuditReport，报告渲染器将审计结果转换为稳定 Markdown。CLI 使用内置项目样例展示审计摘要，测试覆盖解析、策略诊断和报告渲染。",
    ),
    (
        "六、预期成果",
        "项目交付一个独立 MoonBit 审计基础库、可运行 CLI 示例、覆盖核心场景的测试集、README、竞赛申报材料和可复现仓库。后续可扩展真实文件扫描、工作区遍历、依赖图可视化、CI 失败阈值和包仓库审计能力。",
    ),
]


def register_font() -> str:
    for path in [
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/simsun.ttc"),
    ]:
        if path.exists():
            pdfmetrics.registerFont(TTFont("MoonModGuardCN", str(path)))
            return "MoonModGuardCN"
    return "Helvetica"


def build_pdf() -> None:
    font = register_font()
    styles = getSampleStyleSheet()
    title = ParagraphStyle(
        "TitleCN",
        parent=styles["Title"],
        fontName=font,
        fontSize=22,
        leading=30,
        alignment=TA_CENTER,
        spaceAfter=20,
    )
    body = ParagraphStyle(
        "BodyCN",
        parent=styles["BodyText"],
        fontName=font,
        fontSize=10.5,
        leading=17,
        firstLineIndent=21,
        spaceAfter=6,
    )
    heading = ParagraphStyle(
        "HeadingCN",
        parent=styles["Heading2"],
        fontName=font,
        fontSize=13,
        leading=18,
        textColor=colors.HexColor("#1f3b73"),
        spaceBefore=10,
        spaceAfter=6,
    )
    meta = ParagraphStyle(
        "MetaCN",
        parent=styles["BodyText"],
        fontName=font,
        fontSize=10.5,
        leading=16,
    )
    doc = SimpleDocTemplate(
        str(PDF_PATH),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=1.8 * cm,
        bottomMargin=1.8 * cm,
        title=TITLE,
    )
    table = Table(
        [
            [Paragraph("项目名称", meta), Paragraph(PROJECT_NAME, meta)],
            [Paragraph("参赛方向", meta), Paragraph("MoonBit 国产基础软件开源生态项目", meta)],
            [Paragraph("开源许可证", meta), Paragraph("Apache-2.0", meta)],
            [Paragraph("仓库链接", meta), Paragraph("https://gitlink.org.cn/python123/moonmodguard", meta)],
        ],
        colWidths=[3.2 * cm, 12 * cm],
    )
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), font),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#edf3ff")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#9aa9c7")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    story = [Paragraph(TITLE, title), table, Spacer(1, 0.4 * cm)]
    for section_title, text in SECTIONS:
        story.append(Paragraph(section_title, heading))
        story.append(Paragraph(text, body))
    doc.build(story)


def build_docx() -> None:
    doc = Document()
    doc.styles["Normal"].font.name = "Microsoft YaHei"
    doc.styles["Normal"].font.size = Pt(10.5)
    heading = doc.add_heading(TITLE, level=0)
    heading.alignment = 1
    table = doc.add_table(rows=4, cols=2)
    table.style = "Table Grid"
    rows = [
        ("项目名称", PROJECT_NAME),
        ("参赛方向", "MoonBit 国产基础软件开源生态项目"),
        ("开源许可证", "Apache-2.0"),
        ("仓库链接", "https://gitlink.org.cn/python123/moonmodguard"),
    ]
    for row, (key, value) in zip(table.rows, rows):
        row.cells[0].text = key
        row.cells[1].text = value
    for section_title, text in SECTIONS:
        doc.add_heading(section_title, level=1)
        doc.add_paragraph(text)
    doc.save(DOCX_PATH)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    build_pdf()
    build_docx()
    print(PDF_PATH)
    print(DOCX_PATH)


if __name__ == "__main__":
    main()
