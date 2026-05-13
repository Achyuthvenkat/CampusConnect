from fpdf import FPDF
import os

class PatentPDF(FPDF):
    def header(self):
        self.set_font('Helvetica', 'B', 16)
        self.cell(0, 10, 'PATENT APPLICATION DRAFT', 0, 1, 'C')
        self.set_font('Helvetica', 'I', 10)
        self.cell(0, 10, 'For Internal Review and Filing Purposes Only', 0, 1, 'C')
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

    def chapter_title(self, title):
        self.set_font('Helvetica', 'B', 12)
        self.cell(0, 10, title, 0, 1, 'L')
        self.ln(4)

    def chapter_body(self, body):
        self.set_font('Helvetica', '', 11)
        self.multi_cell(0, 6, body)
        self.ln()

def create_patent_pdf(output_path, image_paths):
    pdf = PatentPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    # Title Page
    pdf.add_page()
    pdf.ln(40)
    pdf.set_font('Helvetica', 'B', 18)
    pdf.multi_cell(0, 10, 'SYSTEM AND METHOD FOR SECURED INTRA-CAMPUS DIGITAL SKILL MARKETPLACE AND PROFESSIONAL COLLABORATION', 0, 'C')
    pdf.ln(20)
    pdf.set_font('Helvetica', '', 12)
    pdf.cell(0, 10, 'Project Name: CampusConnect', 0, 1, 'C')
    pdf.cell(0, 10, 'Primary Institution: Saveetha University', 0, 1, 'C')
    pdf.cell(0, 10, 'Draft Date: May 12, 2026', 0, 1, 'C')
    
    # Content
    pdf.add_page()
    pdf.chapter_title('1. FIELD OF THE INVENTION')
    pdf.chapter_body('The present invention relates generally to the field of digital marketplaces and peer-to-peer professional networking. More specifically, it pertains to a mobile-application-based system designed to facilitate secure professional transactions and skill monetization within a closed-loop institutional ecosystem, such as a university campus.')
    
    pdf.chapter_title('2. BACKGROUND OF THE INVENTION')
    pdf.chapter_body('Current freelancing platforms often lack localized security and institutional trust, making it difficult for students within a university to collaborate on small-scale projects or share specialized skills safely. There is a significant need for a system that leverages institutional authentication to verify users and provides a tailored interface for campus-specific gig management.')
    
    pdf.chapter_title('3. SUMMARY OF THE INVENTION')
    pdf.chapter_body('The invention, named "CampusConnect," comprises a mobile computing platform integrated with a cloud-based backend (Firebase/Firestore). The system includes an institutional authentication filter that restricts registration to users with verified "@saveetha.com" credentials. Key features include a real-time bidding system for gigs, integrated end-to-end encrypted messaging, and a dynamic dashboard for tracking project lifecycles.')
    
    pdf.chapter_title('4. BRIEF DESCRIPTION OF THE DRAWINGS')
    pdf.chapter_body('The following figures illustrate the architecture and user interface of the system:')
    
    for i, (title, img_path) in enumerate(image_paths.items(), 1):
        pdf.add_page()
        pdf.set_font('Helvetica', 'B', 12)
        pdf.cell(0, 10, f'Figure {i}: {title}', 0, 1, 'L')
        pdf.ln(5)
        # Scale image to fit
        pdf.image(img_path, x=15, w=180)
        
    # Claims and Abstract
    pdf.add_page()
    pdf.chapter_title('5. CLAIMS')
    pdf.chapter_body('1. A system for intra-campus freelancing comprising:\n   a. An authentication module requiring institutional email verification.\n   b. A gig marketplace module for posting, searching, and bidding.\n   c. A real-time communication module using server-side timestamps for message ordering.\n   d. A dashboard module for managing project statuses (Posted, Active, Done).\n\n2. The system of claim 1, further comprising a premium user interface optimized for academic professionalism and high-utility minimalism.')
    
    pdf.chapter_title('6. ABSTRACT')
    pdf.chapter_body('CampusConnect is a specialized mobile application platform that facilitates professional collaboration within a university campus. By employing strict institutional authentication and providing a high-fidelity interface for gig management and real-time communication, the system creates a trusted environment for students to monetize their skills and for the campus community to source specialized talent.')

    pdf.output(output_path)

if __name__ == '__main__':
    images = {
        'Home & Explore Interface (2D Sketch)': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\home_2d_sketch_1778576215940.png',
        'Gig Detail High-Fidelity View (3D Perspective)': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\gig_detail_3d_sketch_1778576237279.png',
        'Real-Time Messaging Interface (2D Sketch)': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\chat_2d_sketch_1778576259340.png',
        'Project Management Dashboard (3D Perspective)': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\dashboard_3d_sketch_1778576281939.png'
    }
    
    output = r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\CampusConnect_Patent_Draft.pdf'
    create_patent_pdf(output, images)
    print(f'Patent PDF created at: {output}')

