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

TITLE = "MoonModGuard 技术白皮书式项目申报书"
PROJECT_NAME = "MoonModGuard：MoonBit 项目清单与供应链策略审计器"
GITHUB_URL = "https://github.com/Noverberrain/MoonModGuard-MoonBit-"
GITLINK_URL = "https://gitlink.org.cn/Wyc060514/moonmodguard"

SECTIONS = [
    (
        "一、项目定位",
        "MoonModGuard 是面向 MoonBit 生态的项目清单与供应链策略审计器。项目围绕 moon.mod、moon.pkg 等工程清单文件构建轻量审计内核，提取模块元数据、包级依赖、导入别名和发布信息，并通过策略规则生成可复查的审计报告。项目以 GitHub 仓库作为官方开源发布地址，同时保留 GitLink 仓库作为赛事平台镜像。",
    ),
    (
        "二、问题背景",
        "MoonBit 包生态正在增长。一个项目能否稳定发布和复现，不只取决于源码是否能编译，还取决于清单元数据是否完整、许可证是否符合策略、依赖来源是否清晰、包级导入是否可审计。当前很多检查依赖人工阅读，难以形成统一、可测试、可自动化的评审流程。MoonModGuard 将这些工程质量要求转化为可执行规则，为包发布前检查、竞赛仓库验收、课程项目规范检查和后续 CI 集成提供基础组件。",
    ),
    (
        "三、技术架构",
        "系统由清单解析层、项目建模层、策略评估层和报告渲染层组成。清单解析层接收 moon.mod 与 moon.pkg 文本，解析标量字段、数组字段和 import 块；项目建模层将 ModuleManifest 与 PackageManifest 合并为 ProjectModel；策略评估层基于 Policy 检查必填元数据、许可证 allowlist、可信依赖前缀和重复依赖；报告渲染层将 AuditReport 输出为稳定 Markdown，供 CLI、CI 和文档系统复用。",
    ),
    (
        "四、核心功能",
        "项目实现 parse_mod、parse_pkg、project_from、evaluate_policy、scan_project、render_markdown 与 format_error 等核心 API。默认策略检查缺失 README、缺失 repository、缺失 license、非 allowlist 许可证、未知外部依赖和重复依赖。CLI 示例使用内置项目快照展示审计摘要，便于评审者快速验证项目能力。",
    ),
    (
        "五、创新性说明",
        "本项目选择 MoonBit 项目元数据与供应链策略审计这一较冷门但有工程价值的方向，避免与常见格式解析、通用数据结构、解释器、内容寻址或运行日志分析方向重合。项目不追求复杂语法覆盖，而是把 MoonBit 项目的发布准备度、元数据完整性和依赖策略检查抽象为可测试的基础软件能力，具有后续接入 CI、包仓库和教学评测系统的扩展空间。",
    ),
    (
        "六、测试与验证",
        "当前验证覆盖 moon.mod 标量字段解析、keywords 数组字段解析、moon.mod import 解析、moon.pkg import 解析、缺失元数据诊断、非 allowlist 许可证诊断、未知依赖前缀诊断、重复依赖诊断和 Markdown 报告稳定输出。项目验证命令包括 moon info、moon fmt --check、moon test 和 moon run cmd/main。",
    ),
    (
        "七、开源交付",
        "项目交付独立 MoonBit 审计基础库、可运行 CLI 示例、测试集、README、Apache-2.0 许可证、GitHub Actions 配置、竞赛申报材料和可编辑 DOCX/PDF。GitHub 主仓库用于满足赛事章程第五节阶段一对有效 GitHub 仓库链接的要求；GitLink 镜像仓库用于赛事平台提交与同步验收。",
    ),
    (
        "八、后续计划",
        "后续版本可扩展真实文件系统扫描、工作区多包遍历、依赖图可视化、CI 失败阈值、包仓库审计和策略配置文件。首版重点交付可复现、可测试、可演示的审计内核，避免在文件系统、平台集成和网络查询上引入不必要复杂度。",
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
        fontSize=21,
        leading=29,
        alignment=TA_CENTER,
        spaceAfter=18,
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
        fontSize=10,
        leading=15,
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
            [Paragraph("GitHub 主仓库", meta), Paragraph(GITHUB_URL, meta)],
            [Paragraph("GitLink 镜像仓库", meta), Paragraph(GITLINK_URL, meta)],
            [Paragraph("开源许可证", meta), Paragraph("Apache-2.0", meta)],
            [Paragraph("参赛方向", meta), Paragraph("MoonBit 国产基础软件开源生态项目", meta)],
        ],
        colWidths=[3.4 * cm, 11.8 * cm],
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
    story = [Paragraph(TITLE, title), table, Spacer(1, 0.35 * cm)]
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
    table = doc.add_table(rows=5, cols=2)
    table.style = "Table Grid"
    rows = [
        ("项目名称", PROJECT_NAME),
        ("GitHub 主仓库", GITHUB_URL),
        ("GitLink 镜像仓库", GITLINK_URL),
        ("开源许可证", "Apache-2.0"),
        ("参赛方向", "MoonBit 国产基础软件开源生态项目"),
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
