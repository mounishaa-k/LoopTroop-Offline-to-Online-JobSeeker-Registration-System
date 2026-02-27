/// Three sample resume texts in different formats for demo/testing.
class DemoData {
  static const String _page1Sample1 = '''JOHN SMITH
Software Engineer

Phone: +1 (555) 123-4567  |  Mobile: +1 (555) 987-6543
Email: john.smith@email.com  |  john.work@techcorp.com
LinkedIn: linkedin.com/in/johnsmith
GitHub: github.com/johnsmith
Address: 123 Main Street, San Francisco, CA 94105

PROFESSIONAL SUMMARY
Results-driven Software Engineer with 5+ years of experience building
scalable full-stack applications. Passionate about clean architecture,
cloud-native solutions, and developer tooling. Strong background in
Python, React, and distributed systems.

EDUCATION
B.S. Computer Science | Stanford University | 2015 - 2019 | GPA: 3.8/4.0
Minor: Mathematics | Dean's List: 2017, 2018, 2019

WORK EXPERIENCE
Senior Software Engineer — TechCorp Inc.
San Francisco, CA  |  Jan 2021 – Present
- Led architecture of a microservices platform serving 2M+ daily users.
- Reduced API latency by 40% through caching and query optimization.
- Mentored a team of 5 junior engineers.

Software Engineer — StartupXYZ
San Jose, CA  |  Jun 2019 – Dec 2020
- Built REST APIs using Python/Django serving 500k users.
- Implemented CI/CD pipeline reducing deployment time by 70%.
- Contributed to React frontend for the main SaaS dashboard.
''';

  static const String _page2Sample1 = '''JOHN SMITH — Page 2

SKILLS
Python, JavaScript, TypeScript, Go, React, Node.js, Django, FastAPI
Docker, Kubernetes, AWS, GCP, PostgreSQL, Redis, Elasticsearch

LANGUAGES
English (Native), Spanish (Intermediate), French (Basic)

CERTIFICATIONS
AWS Certified Solutions Architect – Associate (2022)
Google Cloud Professional Cloud Developer (2021)
Kubernetes Application Developer (CKAD) (2020)

PROJECTS
OpenAPI Generator Plugin — open-source tool with 2k+ GitHub stars
Real-time Chat App — WebSocket-based, deployed on AWS ECS

Availability: Immediate
Notice Period: 2 weeks
Expected Salary: \$130,000 - \$150,000 / year
''';

  static const String _page1Sample2 = '''Dr. Sarah A. Johnson, PhD

Department of Computer Science, University of London
Contact: sarah.johnson@uni-london.ac.uk | s.johnson@gmail.com
Telephone: +44 20 7946 0958
ORCID: 0000-0001-2345-6789
Website: https://sarahjohnson.github.io
GitHub: github.com/sarahjnlp

About Me
Researcher and educator with 9 years of post-doctoral experience in
machine learning, natural language processing, and computational linguistics.
Published 34 peer-reviewed papers with 1,200+ citations.

Academic Background
PhD Computer Science — Massachusetts Institute of Technology — 2012–2017
Thesis: "Deep Learning Architectures for Low-Resource NLP Tasks"
Supervisor: Prof. Yoshua Bengio

MSc Artificial Intelligence — University of Cambridge — 2010–2012
Distinction | Thesis prize winner

BSc Mathematics — University of Oxford — 2007–2010
First Class Honours

Professional History
Associate Professor
Department of Computer Science, University of London
2020 – Present
Teaching graduate ML, NLP, and Deep Learning courses.
Grant recipient: EPSRC £450k research grant (2021).

Research Scientist
Google DeepMind, London
2017 – 2020
Developed BERT fine-tuning strategies for low-resource languages.
Led team of 4 researchers; published 12 papers in NeurIPS/EMNLP/ACL.
''';

  static const String _page2Sample2 =
      '''Dr. Sarah Johnson — Curriculum Vitae (cont.)

Technical Competencies
Python (Expert), R, Julia, MATLAB, C++
TensorFlow, PyTorch, JAX, Hugging Face Transformers
Spark, Hadoop, Docker, Kubernetes, GCP

Languages Spoken
English (Native), French (Fluent), German (Intermediate)

Selected Publications
1. Johnson et al. (2023), "Multilingual LLM Alignment", NeurIPS 2023.
2. Johnson & Smith (2022), "Cross-lingual Transfer for Low-Resource NLP", ACL 2022.
3. Johnson et al. (2021), "BERT for African Languages", EMNLP 2021.

Professional Certifications
Deep Learning Specialization — Coursera / deeplearning.ai (2021)
Machine Learning Engineering for Production — DeepLearning.AI (2022)

Awards & Achievements
Best Paper Award — EMNLP 2021
Outstanding Reviewer — ACL 2020
Research Excellence Award — University of London (2022)
''';

  static const String _page1Sample3 = '''Maria Garcia
maria.garcia@hotmail.com | 0812-345-6789 | 0744-987-6543

About
I am an experienced marketing professional with a passion for digital
marketing, brand strategy and communications. 8 years experience across
FMCG, tourism and agency sectors. Available for immediate start.

Educational Qualifications
- Bachelor of Commerce in Marketing
  University of Cape Town | 2014 – 2018
- Certificate in Digital Marketing, Google (2019)
- Certificate in Project Management, PMI (2020)

Career History
Marketing Manager | Cape Town Tourism Board | 2021 – Present
  Led integrated marketing campaigns increasing digital engagement by 40%.
  Managed R2.5M annual marketing budget.
  Team of 6 direct reports.

Digital Marketing Specialist | Creative Agency Co. | 2018 – 2021
  Managed SEO/SEM campaigns for 20+ clients across retail and hospitality.
  Grew organic traffic 150% YoY for key accounts.
  Adobe Analytics, Google Ads, Facebook Business Manager.

Key Skills
Digital Marketing, SEO/SEM, Content Strategy, Google Analytics, Facebook Ads,
Adobe Creative Suite (Photoshop, Illustrator, InDesign), Copywriting,
Brand Strategy, CRM (Salesforce), Email Marketing (Mailchimp)

Languages: English (Fluent), Afrikaans (Native), Zulu (Basic)

Expected Salary: R35,000 – R40,000/month
Availability: Immediate | Notice Period: 1 month
''';

  static List<String> getSampleTexts(int sampleIndex) {
    switch (sampleIndex) {
      case 0:
        return [_page1Sample1, _page2Sample1];
      case 1:
        return [_page1Sample2, _page2Sample2];
      case 2:
        return [_page1Sample3];
      default:
        return [_page1Sample1, _page2Sample1];
    }
  }

  static String getSampleTitle(int index) {
    switch (index) {
      case 0:
        return 'Sample 1 — US Tech Resume (2 pages)';
      case 1:
        return 'Sample 2 — Academic CV / European Format (2 pages)';
      case 2:
        return 'Sample 3 — SA Marketing Resume, Informal (1 page)';
      default:
        return 'Sample ${index + 1}';
    }
  }

  static int get sampleCount => 3;
}
