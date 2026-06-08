import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARTICLES_PATH = ROOT / "assets" / "data" / "articles.json"
QUESTIONS_PATH = ROOT / "assets" / "data" / "questions.json"

GENERIC_DISTRACTORS = [
    "보험료를 납부한 날",
    "요양급여를 신청한 날",
    "건강검진을 받은 날",
    "보험증을 발급받은 날",
    "공단에 민원을 제기한 날",
    "진료를 받은 날",
    "심사청구를 한 날",
    "보험료 고지서를 받은 날",
]


def clean_text(text: str, max_length: int | None = 90) -> str:
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\[[^\]]+\]", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    text = text.strip()
    if max_length is None or len(text) <= max_length:
        return text
    return text[:max_length].rstrip() + "..."


def first_sentence(article: dict) -> str:
    source = article["content"] or article["summary"]
    text = clean_text(source, None)
    match = re.search(r".*?다\.", text)
    if match:
        return clean_text(match.group(0), None)
    return clean_text(text, None)


def article_items(article: dict) -> list[str]:
    content = article["content"].replace("\r\n", "\n")
    pattern = re.compile(
        r"(?:^|\n)(\d+)\.\s+(.+?)(?=\n\d+\.\s+|\n[①②③④⑤⑥⑦⑧⑨⑩]|\Z)",
        re.S,
    )
    items = []
    for _, item in pattern.findall(content):
        item = clean_text(item, 80)
        if 4 <= len(item) <= 85 and item not in items:
            items.append(item)
    return items


def question_stem(article: dict) -> str:
    law_name = article["lawName"]
    title = article["title"]
    if "상실" in title:
        return f"{law_name}상 {title}에 해당하는 것은?"
    if "취득" in title:
        return f"{law_name}상 {title}에 해당하는 것은?"
    if "종류" in title:
        return f"{law_name}상 {title}로 맞는 것은?"
    if "대상" in title:
        return f"{law_name}상 {title}에 포함되는 것은?"
    if "사항" in title or "내용" in title:
        return f"{law_name}상 {title}에 포함되는 것은?"
    if "급여" in title:
        return f"{law_name}상 {title}와 관련된 내용으로 맞는 것은?"
    return f"{law_name}상 {title}의 내용으로 맞는 것은?"


def ox_stem(article: dict) -> str:
    law_name = article["lawName"]
    title = article["title"]
    if "상실" in title:
        return f"{law_name}상 {title}에 관한 설명으로 맞으면 O, 틀리면 X를 고르세요."
    if "취득" in title:
        return f"{law_name}상 {title}에 관한 설명으로 맞으면 O, 틀리면 X를 고르세요."
    if "종류" in title:
        return f"{law_name}상 {title}에 관한 설명으로 맞으면 O, 틀리면 X를 고르세요."
    if "대상" in title:
        return f"{law_name}상 {title}에 관한 설명으로 맞으면 O, 틀리면 X를 고르세요."
    if "급여" in title:
        return f"{law_name}상 {title}에 관한 설명으로 맞으면 O, 틀리면 X를 고르세요."
    return f"{law_name}상 {title}에 관한 설명으로 맞으면 O, 틀리면 X를 고르세요."


def should_make_ox(article: dict, items: list[str]) -> bool:
    title = article["title"]
    if not items:
        return False
    allowed_titles = {
        "가입자의 종류",
        "자격의 취득 시기 등",
        "자격의 상실 시기 등",
        "요양급여",
        "급여의 제한",
        "급여의 정지",
        "장기요양급여의 종류",
        "급여외행위의 제공 금지",
        "장기요양기관의 지정",
    }
    if title not in allowed_titles:
        return False
    if not topic_distractors(article):
        return False
    return any(len(item) >= 8 and "..." not in item for item in items)


def topic_distractors(article: dict) -> list[str]:
    title = article["title"]
    if "상실" in title:
        return [
            "보험료를 납부한 날",
            "요양급여를 신청한 날",
            "건강검진을 받은 날",
            "보험증을 발급받은 날",
        ]
    if "취득" in title:
        return [
            "요양급여를 받은 날",
            "보험료 고지서를 받은 날",
            "심사청구를 한 날",
            "건강검진 결과를 통보받은 날",
        ]
    if "급여" in title:
        return [
            "주택 구입비",
            "일반 생활비",
            "교통 범칙금",
            "사적 여행비",
        ]
    if "지정" in title:
        return [
            "단순 상담 실적",
            "민원 접수 사실",
            "보험료 납부 실적",
            "건강검진 수검 이력",
        ]
    return []


def shuffled_options(answer: str, distractors: list[str], seed: str) -> list[str]:
    options = [answer]
    for item in distractors:
        if item != answer and item not in options:
            options.append(item)
        if len(options) == 4:
            break

    for filler in GENERIC_DISTRACTORS:
        if len(options) == 4:
            break
        if filler not in options:
            options.append(filler)

    shift = sum(ord(char) for char in seed) % len(options)
    return options[shift:] + options[:shift]


def collect_item_pool(articles: list[dict]) -> dict[str, list[str]]:
    pool: dict[str, list[str]] = {}
    for article in articles:
        pool.setdefault(article["lawId"], [])
        for item in article_items(article):
            if item not in pool[article["lawId"]]:
                pool[article["lawId"]].append(item)
    return pool


def neighbor_summaries(article: dict, articles: list[dict]) -> list[str]:
    same_law = [item for item in articles if item["lawId"] == article["lawId"]]
    index = same_law.index(article)
    summaries = []
    for offset in (1, -1, 2, -2, 3, -3, 4, -4):
        other_index = index + offset
        if 0 <= other_index < len(same_law):
            summary = first_sentence(same_law[other_index])
            if summary and summary not in summaries:
                summaries.append(summary)
    return summaries


def build_questions(articles: list[dict]) -> list[dict]:
    questions = []
    item_pool = collect_item_pool(articles)

    for article in articles:
        items = article_items(article)
        answer_items = items[:3] if items else [first_sentence(article)]
        ox_answer_items = answer_items[:2]
        law_pool = item_pool.get(article["lawId"], [])
        distractors = topic_distractors(article)
        if not items:
            distractors = neighbor_summaries(article, articles)
        distractors.extend(item for item in law_pool if item not in items)

        for index, answer_item in enumerate(answer_items, start=1):
            seed = f"{article['id']}-{index}"
            if index <= len(ox_answer_items) and should_make_ox(article, items):
                ox_is_true = sum(ord(char) for char in seed) % 2 == 0
                if ox_is_true:
                    ox_statement = answer_item
                    ox_answer = "O"
                elif topic_distractors(article):
                    ox_statement = topic_distractors(article)[
                        (index - 1) % len(topic_distractors(article))
                    ]
                    ox_answer = "X"
                else:
                    ox_statement = ""
                    ox_answer = ""

                if ox_statement:
                    questions.append(
                        {
                            "id": f"{article['id']}-ox-{index}",
                            "type": "ox",
                            "articleId": article["id"],
                            "question": f"{ox_stem(article)}\n{ox_statement}",
                            "answer": ox_answer,
                            "options": ["O", "X"],
                            "explanation": f"{article['lawName']} {article['articleNumber']}({article['title']})의 정리: {answer_item}",
                        }
                    )

            questions.append(
                {
                    "id": f"{article['id']}-multiple-{index}",
                    "type": "multiple",
                    "articleId": article["id"],
                    "question": question_stem(article),
                    "answer": answer_item,
                    "options": shuffled_options(answer_item, distractors, seed),
                    "explanation": f"{article['lawName']} {article['articleNumber']}({article['title']})에 규정된 내용입니다.",
                }
            )

    return questions


def main() -> None:
    articles = json.loads(ARTICLES_PATH.read_text(encoding="utf-8"))
    questions = build_questions(articles)
    QUESTIONS_PATH.write_text(
        json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"articles={len(articles)} questions={len(questions)}")


if __name__ == "__main__":
    main()
