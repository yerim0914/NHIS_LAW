import json
import re
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "assets" / "data"

SOURCES = [
    {
        "law_id": "national_health_insurance",
        "law_name": "국민건강보험법",
        "pdf": Path(
            r"C:\Users\우태\Downloads\3._(별첨2)_직무시험_관련_국민건강보험법_및_노인장기요양법\(법률 제21065호) 국민건강보험법_20251001.pdf"
        ),
    },
    {
        "law_id": "long_term_care",
        "law_name": "노인장기요양보험법",
        "pdf": Path(
            r"C:\Users\우태\Downloads\3._(별첨2)_직무시험_관련_국민건강보험법_및_노인장기요양법\(법률 제21257호) 노인장기요양보험법_20251230.pdf"
        ),
    },
]


ARTICLE_RE = re.compile(r"^제(\d+)조(?:의(\d+))?\s*\((.+)\)\s*$")
CHAPTER_RE = re.compile(r"^제\d+장\s+.+$")
HEADER_RE = re.compile(r"^\[\s*시행|^\[\s*법률|^\[\s*보건복지부")
FOOTER_RE = re.compile(r"국민건강보험공단\s+-\s+\d+\s+-\s+법령정보\s+건강Law")


def clean_line(line: str, law_name: str) -> str:
    line = re.sub(r"\s+", " ", line).strip()
    if not line:
        return ""
    if line == law_name:
        return ""
    if FOOTER_RE.search(line):
        return ""
    if HEADER_RE.search(line):
        return ""
    return line


def article_sort_key(article_number: str) -> str:
    match = re.match(r"제(\d+)조(?:의(\d+))?", article_number)
    if not match:
        return article_number
    main = int(match.group(1))
    sub = int(match.group(2) or 0)
    return f"{main:04d}-{sub:04d}"


def make_summary(content: str) -> str:
    text = re.sub(r"<[^>]+>", "", content)
    text = re.sub(r"\[[^\]]+\]", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return "조문 내용 확인"
    sentence = re.split(r"(?<=[.다])\s+", text, maxsplit=1)[0]
    return sentence[:90] + ("..." if len(sentence) > 90 else "")


def extract_articles(source: dict) -> list[dict]:
    reader = PdfReader(str(source["pdf"]))
    lines: list[str] = []
    in_appendix = False
    for page in reader.pages:
        text = page.extract_text() or ""
        for raw_line in text.splitlines():
            line = clean_line(raw_line, source["law_name"])
            if line.startswith("부칙"):
                in_appendix = True
            if in_appendix:
                continue
            if line:
                lines.append(line)

    articles: list[dict] = []
    current_chapter = "기타"
    current: dict | None = None
    body: list[str] = []

    def flush() -> None:
        nonlocal current, body
        if current is None:
            return
        content = "\n".join(body).strip()
        current["content"] = content
        current["summary"] = make_summary(content)
        articles.append(current)
        current = None
        body = []

    for line in lines:
        if CHAPTER_RE.match(line):
            current_chapter = line
            continue

        article_match = ARTICLE_RE.match(line)
        if article_match:
            flush()
            main, sub, title = article_match.groups()
            article_number = f"제{main}조" + (f"의{sub}" if sub else "")
            current = {
                "id": f"{source['law_id']}-{main}" + (f"-{sub}" if sub else ""),
                "lawId": source["law_id"],
                "lawName": source["law_name"],
                "articleNumber": article_number,
                "title": title.strip(),
                "chapter": current_chapter,
                "sortKey": f"{source['law_id']}-{article_sort_key(article_number)}",
            }
            continue

        if current is not None:
            body.append(line)

    flush()
    return articles


def build_questions(articles: list[dict]) -> list[dict]:
    by_number = {
        (article["lawName"], article["articleNumber"]): article for article in articles
    }

    def q(
        qid: str,
        law_name: str,
        article_number: str,
        qtype: str,
        question: str,
        answer: str,
        options: list[str],
        explanation: str,
    ) -> dict:
        article = by_number[(law_name, article_number)]
        return {
            "id": qid,
            "type": qtype,
            "articleId": article["id"],
            "question": question,
            "answer": answer,
            "options": options,
            "explanation": explanation,
        }

    return [
        q(
            "q-nhi-1",
            "국민건강보험법",
            "제1조",
            "ox",
            "국민건강보험법의 목적에는 국민보건 향상과 사회보장 증진이 포함된다.",
            "O",
            ["O", "X"],
            "제1조는 보험급여 실시를 통해 국민보건 향상과 사회보장 증진에 이바지함을 목적으로 한다.",
        ),
        q(
            "q-nhi-2",
            "국민건강보험법",
            "제2조",
            "ox",
            "국민건강보험법상 건강보험사업은 보건복지부장관이 맡아 주관한다.",
            "O",
            ["O", "X"],
            "제2조는 건강보험사업의 관장 주체를 보건복지부장관으로 정한다.",
        ),
        q(
            "q-nhi-6",
            "국민건강보험법",
            "제6조",
            "multiple",
            "국민건강보험법상 가입자의 종류로 맞는 것은?",
            "직장가입자와 지역가입자",
            ["직장가입자와 지역가입자", "임의가입자와 당연가입자", "근로가입자와 사업가입자", "보험가입자와 급여가입자"],
            "제6조는 가입자를 직장가입자와 지역가입자로 구분한다.",
        ),
        q(
            "q-ltc-1",
            "노인장기요양보험법",
            "제1조",
            "ox",
            "노인장기요양보험법의 목적에는 가족의 부담을 덜어주는 것이 포함된다.",
            "O",
            ["O", "X"],
            "제1조는 노후의 건강증진 및 생활안정을 도모하고 그 가족의 부담을 덜어 국민 삶의 질을 향상하도록 함을 목적으로 한다.",
        ),
        q(
            "q-ltc-2",
            "노인장기요양보험법",
            "제2조",
            "multiple",
            "노인장기요양보험법상 '노인등'에 관한 설명으로 맞는 것은?",
            "65세 이상의 노인 또는 대통령령으로 정하는 노인성 질병을 가진 65세 미만의 자",
            [
                "65세 이상의 노인 또는 대통령령으로 정하는 노인성 질병을 가진 65세 미만의 자",
                "모든 60세 이상의 국민",
                "장기요양기관에 근무하는 요양보호사",
                "건강보험 직장가입자만",
            ],
            "제2조제1호는 노인등의 정의를 65세 이상의 노인 또는 65세 미만의 노인성 질병을 가진 자로 정한다.",
        ),
        q(
            "q-ltc-7",
            "노인장기요양보험법",
            "제7조",
            "ox",
            "장기요양보험사업의 보험자는 국민건강보험공단이다.",
            "O",
            ["O", "X"],
            "제7조는 장기요양보험사업의 보험자를 공단으로 한다.",
        ),
    ]


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    articles: list[dict] = []
    for index, source in enumerate(SOURCES):
        source_articles = extract_articles(source)
        for article in source_articles:
            article["sortKey"] = f"{index:02d}-{article['sortKey']}"
        articles.extend(source_articles)

    articles.sort(key=lambda item: item["sortKey"])
    for article in articles:
        article.pop("sortKey", None)

    questions = build_questions(articles)
    (DATA_DIR / "articles.json").write_text(
        json.dumps(articles, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (DATA_DIR / "questions.json").write_text(
        json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"articles={len(articles)} questions={len(questions)}")
    for law_name in sorted({article["lawName"] for article in articles}):
        count = sum(1 for article in articles if article["lawName"] == law_name)
        print(f"{law_name}: {count}")


if __name__ == "__main__":
    main()
