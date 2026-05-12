from fpdf import FPDF
import os

class SketchPDF(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 15)
        self.cell(0, 10, 'CampusConnect Interface Sketches', 0, 1, 'C')
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

def create_sketch_pdf(image_paths, output_path):
    pdf = SketchPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    for title, img_path in image_paths.items():
        pdf.add_page()
        pdf.set_font('Arial', 'B', 12)
        pdf.cell(0, 10, title, 0, 1, 'L')
        pdf.ln(5)
        
        # Add image and scale to fit page width
        # A4 width is 210mm, with 10mm margins on each side, we have 190mm
        pdf.image(img_path, x=10, w=190)
        
    pdf.output(output_path)

if __name__ == '__main__':
    images = {
        'Home Screen - 2D Pencil Sketch': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\home_2d_sketch_1778576215940.png',
        'Gig Detail Screen - 3D Perspective Sketch': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\gig_detail_3d_sketch_1778576237279.png',
        'Chat Room - 2D Ink Sketch': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\chat_2d_sketch_1778576259340.png',
        'Dashboard - 3D Architectural Sketch': r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\dashboard_3d_sketch_1778576281939.png'
    }
    
    output = r'C:\Users\achyu\.gemini\antigravity\brain\cc7541ff-74de-460a-9054-268a082e74c6\CampusConnect_Sketches.pdf'
    create_sketch_pdf(images, output)
    print(f'PDF created at: {output}')

