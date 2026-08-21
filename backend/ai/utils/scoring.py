"""Deterministic risk aggregation — scores are never random."""
from __future__ import annotations

from typing import Literal

RiskLevel = Literal["low", "medium", "high", "critical", "unknown"]

SEVERITY_WEIGHT = {"low": 1, "medium": 2, "high": 4, "critical": 8}


def aggregate_risk(findings: list[dict]) -> tuple[int, RiskLevel, float]:
    """
    Returns (score 0-100, risk_level, confidence 0-1).
    Higher score = more dangerous for offers; for resumes lower safety_score = worse.
    """
    if not findings:
        return 0, "low", 0.5

    total_weight = 0.0
    weighted_sum = 0.0
    confidences: list[float] = []

    for f in findings:
        sev = f.get("risk_level", "medium")
        w = SEVERITY_WEIGHT.get(sev, 2)
        conf = float(f.get("confidence", 0.7))
        confidences.append(conf)
        weighted_sum += w * conf
        total_weight += w

    if total_weight <= 0:
        return 0, "unknown", 0.0

    raw = (weighted_sum / total_weight) * 12.5  # scale to ~0-100
    score = min(100, max(0, int(round(raw))))

    if score >= 75:
        level: RiskLevel = "critical"
    elif score >= 50:
        level = "high"
    elif score >= 25:
        level = "medium"
    else:
        level = "low"

    confidence = sum(confidences) / len(confidences) if confidences else 0.0
    return score, level, min(1.0, confidence)


def classify_resume_document(text: str, file_name: str = "") -> tuple[bool, dict[str, bool], str]:
    """
    Evaluates whether text is a valid Resume/CV vs non-resume (assignment, meeting notes, business doc, essay, coursework).
    Returns (is_resume, section_checks, reasoning).
    """
    import re
    lower = text.lower()
    fn_lower = file_name.lower()
    
    # Filename non-resume indicators
    fn_non_resume_markers = [
        "assesment", "assessment", "assignment", "homework", "question", "quiz", "exam",
        "syllabus", "rubric", "timetable", "admitcard", "hallticket", "coursework", "labmanual",
        "co1", "co2", "co3", "co4", "co5", "unit1", "unit2", "unit3", "unit4", "unit5",
        "module1", "module2", "module3"
    ]
    fn_hits = [m for m in fn_non_resume_markers if m in fn_lower]

    # Explicit non-resume document indicators (specific academic & administrative terms)
    non_resume_markers = [
        "statement of marks", "grade card", "mark sheet", "academic transcript", "transcript of records",
        "digilocker", "national academic depository", "result : pass", "result: pass", "sgpa :", "cgpa :",
        "we're hiring", "we are hiring", "now hiring", "job description", "job vacancy",
        "role details", "interview details", "interview date", "interview time", "walk-in interview",
        "minutes of meeting", "mom page", "meeting notes", "meeting date",
        "homework assignment", "assignment 1", "assignment 2", "assignment", "submitted by", "submitted to", "guided by",
        "project report", "project title", "project work", "project assignment", "project guide", "project synopsis",
        "project proposal", "project documentation", "capstone project", "mini project", "mini-project", "lab report",
        "question 1", "question 2", "q1.", "q2.", "table of contents", "abstract", "conclusion",
        "proposed system flow", "functional specification", "bibliography",
        "invoice", "receipt", "terms of service", "privacy policy", "bill of quantities",
        "question paper", "exam paper", "assessment tool", "assessment", "assesment", "lab manual", "coursework",
        "max marks", "max. marks", "time allowed", "subject code", "course code", "register number", "reg. no", "roll no",
        "programming in java", "programming in c", "programming in python", "programming in c++",
        "data structures and", "computer networks", "database management", "operating systems",
        "answer all questions", "answer any five", "multiple choice", "section a", "section b", "section c",
        "course outcome", "program outcome", "blooms taxonomy", "cognitive level",
        "submitted in partial fulfillment", "department of", "academic year",
        "signature of staff", "signature of the staff", "signature of student", "signature of the student",
        "signature of faculty", "signature of the faculty", "signature of guide", "signature of the guide",
        "signature of evaluator", "signature of the evaluator", "signature of hod", "signature of the hod",
        "signature of principal", "signature of the principal", "signature of supervisor", "signature of the supervisor",
        "signature of teacher", "signature of the teacher", "signature of candidate", "signature of the candidate",
        "staff signature", "student signature", "faculty signature", "hod signature", "guide signature", "evaluator signature",
        "supervisor signature", "principal signature", "staff sig", "faculty sig", "student sig", "hod sig", "guide sig",
        "date of submission", "submission date", "date of evaluation", "evaluation date", "evaluated by", "verified by", "checked by", "approved by",
        "parent signature", "guardian signature"
    ]
    non_resume_regexes = [
        r"signature\s*of\s*(the\s*)?(parent|guardian|student|faculty|staff|guide|evaluator|hod|principal|supervisor|teacher|candidate)",
        r"(parent|guardian|student|faculty|staff|guide|evaluator|hod|principal|supervisor|teacher)['']?s?\s*signature",
        r"date\s*of\s*(submission|evaluation|experiment)",
        r"(submission|evaluation|experiment)\s*date",
        r"\bsignature\s*:",
        r"\b(ex\.?\s*no|experiment\s*no|exercise\s*no)\b",
        r"\b(aim|objective|procedure|algorithm|observation|inference)\s*:",
        r"\b(evaluated|verified|checked|approved)\s*by\b",
        r"\b(assignment|homework|coursework|lab\s*manual|question\s*paper|assessment)\b",
        r"\b(project\s*report|project\s*title|project\s*work|mini\s*project|capstone\s*project|lab\s*report)\b",
    ]
    non_resume_hits = [m for m in non_resume_markers if m in lower]
    regex_hits = [r for r in non_resume_regexes if re.search(r, text, re.IGNORECASE)]
    has_non_resume_match = len(non_resume_hits) >= 1 or len(regex_hits) >= 1

    # Strict contact info check: Requires actual email or phone number format.
    # Bare 10-digit runs are excluded unless they look like a real phone number
    # (country code, separators, or a valid Indian mobile prefix) — otherwise a
    # register/roll number on an assignment cover page reads as a phone number.
    has_email = bool(re.search(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', text))
    has_phone = bool(
        re.search(r'\+\d{1,3}[\s\-]?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{4}', text)
        or re.search(r'\(?\d{3}\)?[\s\-]\d{3}[\s\-]\d{4}', text)
        or re.search(r'(?<!\d)[6-9]\d{9}(?!\d)', text)
    )
    has_contact = has_email or has_phone

    # Check for core resume section markers (requiring specific resume context)
    section_checks = {
        "contact_info": has_contact,
        "education": any(w in lower for w in ["education", "academic", "qualification", "degree", "bachelor", "master", "university", "college", "gpa", "cgpa", "b.e", "b.tech", "m.tech", "b.sc", "m.sc", "bca", "mca"]),
        "experience": any(w in lower for w in ["experience", "internship", "internships", "employment", "work experience", "professional experience", "work history", "career history"]),
        "skills": any(w in lower for w in ["skills", "skill", "technologies", "proficiencies", "technical skills", "competencies", "expertise"]),
        "projects": any(w in lower for w in ["projects", "project", "personal projects", "key projects", "portfolio", "accomplishments"]),
    }

    # Count core resume sections (excluding contact_info)
    core_sections = [section_checks[k] for k in ["education", "experience", "skills", "projects"]]
    core_section_count = sum(1 for present in core_sections if present)
    has_cv_title = any(w in lower for w in ["resume", "curriculum vitae", "curriculum-vitae"])

    # Classification decision:
    # 0. Filename markers always reject — a stray "resume"/"CV" mention elsewhere in an
    # assignment's text must not override an explicit non-resume filename.
    if fn_hits:
        return False, section_checks, f"File name indicates an academic or non-resume document type ({fn_hits[0]})."

    # 1. Explicit non-resume markers always reject, even if the document also contains the
    # word "resume" or "CV" somewhere (e.g. used as a verb, or as an abbreviation for something
    # else like "Control Volume"). has_cv_title only relaxes checks 2/3 below, never this one —
    # otherwise a single incidental match disables every other safety check.
    if has_non_resume_match:
        hit_desc = non_resume_hits[0] if non_resume_hits else "academic/signature format"
        return False, section_checks, f"Document identified as non-resume document type ({hit_desc})."

    # 2. If no candidate contact info (email or phone), reject immediately
    if not has_contact and not has_cv_title:
        return False, section_checks, "Document lacks candidate contact information (email or phone number) required for a resume."

    # 3. If candidate contact info (or CV title) is present AND at least 3 of the 4 core
    # resume sections are present, it is a VALID RESUME. Requiring 3 (not 2) avoids accepting
    # academic documents that happen to mention two resume-adjacent words in passing.
    if (has_contact or has_cv_title) and (core_section_count >= 3 or has_cv_title):
        return True, section_checks, "Valid resume structure detected."

    # 4. Fallback: Lack of core resume sections
    return False, section_checks, "Document lacks core resume sections (Work Experience, Technical Skills, Education, or Projects)."


def classify_offer_document(text: str) -> tuple[bool, dict[str, bool], str]:
    """
    Evaluates whether text is a valid Offer Letter / Appointment Letter vs non-offer (Resume, Grade sheet, Assignment, Essay, Exam/Assessment).
    Returns (is_offer, offer_checks, reasoning).
    """
    import re
    lower = text.lower()

    # Core offer letter markers
    has_offer_title = any(w in lower for w in [
        "offer letter", "letter of offer", "appointment letter", "internship offer",
        "employment offer", "job offer", "selection letter", "confirmation letter"
    ])
    has_joining_date = any(w in lower for w in [
        "joining date", "start date", "commencement date", "reporting date", "date of joining", "doj"
    ])
    has_compensation = any(w in lower for w in [
        "stipend", "salary", "ctc", "remuneration", "per month", "p.m", "per annum", "p.a", "compensation", "allowance"
    ])
    has_role = any(w in lower for w in [
        "designation", "position", "role", "responsibilities", "title:", "intern", "developer", "engineer", "trainee"
    ])
    has_terms = any(w in lower for w in [
        "terms of employment", "probation", "working hours", "confidentiality", "validity", "duration", "tenure"
    ])

    offer_checks = {
        "offer_title": has_offer_title,
        "joining_date": has_joining_date,
        "compensation": has_compensation,
        "role": has_role,
        "terms": has_terms,
    }

    # Explicit non-offer document markers (Resumes, Grade sheets, Assignments, Essays, Exam/Assessment tools, Meeting minutes)
    non_offer_markers = [
        "statement of marks", "grade card", "mark sheet", "academic transcript", "transcript of records",
        "digilocker", "national academic depository", "result : pass", "result: pass", "sgpa :", "cgpa :",
        "about me", "technical skills", "languages known", "developer tools", "curriculum vitae",
        "assessment tool", "course name", "course code", "experiments rubric", "taxonomy", "total marks",
        "marks awarded", "register number", "weightage", "rubric", "lab manual", "experiment",
        "question paper", "answer sheet", "exam", "midterm", "end semester",
        "minutes of meeting", "mom page", "meeting notes", "meeting date",
        "homework assignment", "assignment 1", "assignment 2", "submitted by",
        "question 1", "question 2", "q1.", "q2.", "table of contents",
        "proposed system flow", "functional specification",
        "invoice", "receipt", "terms of service", "privacy policy", "bill of quantities"
    ]
    non_offer_hits = [m for m in non_offer_markers if m in lower]

    # Classification decision:
    # 1. If explicit non-offer markers are present and no explicit offer title:
    if len(non_offer_hits) >= 1 and not has_offer_title:
        return False, offer_checks, f"Document identified as non-offer document type ({', '.join(non_offer_hits[:2])})."

    # 2. If explicit offer title is present, it is a valid offer letter:
    if has_offer_title:
        return True, offer_checks, "Valid offer letter structure detected."

    # 3. Without explicit offer title, must have BOTH compensation (stipend/salary) AND joining date:
    if has_compensation and has_joining_date and (has_role or has_terms):
        return True, offer_checks, "Valid offer letter structure detected."

    # 4. Otherwise, flag as lacking core offer sections
    return False, offer_checks, "Document lacks core offer letter sections (Offer Title, Stipend/Salary, and Joining Date)."



def evaluate_resume_quality(text: str, findings: list[dict]) -> tuple[int, dict[str, bool], list[str]]:
    """
    Computes ATS & Structure Quality Score (0-100), section checks, and ATS recommendations.
    """
    is_res, checks, reason = classify_resume_document(text)
    if not is_res:
        return 0, checks, [reason]

    lower = text.lower()
    score = 40  # base score for valid resume

    # Section completeness (+35 pts)
    if checks["education"]: score += 8
    if checks["experience"]: score += 8
    if checks["skills"]: score += 8
    if checks["projects"]: score += 6
    if checks["contact_info"]: score += 5

    # Action verbs (+15 pts)
    action_verbs = [
        "built", "developed", "designed", "engineered", "implemented",
        "created", "managed", "led", "optimized", "increased", "reduced",
        "automated", "collaborated", "orchestrated", "spearheaded"
    ]
    verb_hits = [v for v in action_verbs if v in lower]
    score += min(15, len(verb_hits) * 3)

    # Length & formatting (+10 pts)
    words = text.split()
    if 100 <= len(words) <= 1000:
        score += 10
    elif len(words) > 50:
        score += 5

    # PII Deductions (max -20 pts)
    pii_count = len(findings)
    score = max(0, min(100, score - (pii_count * 10)))

    # Generate recommendations
    recs: list[str] = []
    if not checks["experience"]:
        recs.append("Add a Work Experience or Internship section to boost recruiter visibility.")
    if not checks["projects"]:
        recs.append("Include a Projects section highlighting technical work and personal projects.")
    if len(verb_hits) < 3:
        recs.append("Use strong action verbs (e.g. Developed, Built, Optimized) to describe achievements.")
    if pii_count > 0:
        recs.append("Remove sensitive personal numbers (Aadhaar/PAN/passwords) to protect your privacy.")

    return score, checks, recs


def resume_safety_score(findings: list[dict]) -> tuple[int, RiskLevel, float]:
    """Resume: 100 = safe, 0 = critical exposure."""
    danger, level, conf = aggregate_risk(findings)
    safety = max(0, min(100, 100 - danger))
    if safety >= 85:
        rl: RiskLevel = "low"
    elif safety >= 65:
        rl = "medium"
    elif safety >= 40:
        rl = "high"
    else:
        rl = "critical"
    return safety, rl, conf


