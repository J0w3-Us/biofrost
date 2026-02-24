import { useState, useRef } from 'react';
import html2canvas from 'html2canvas';
import { jsPDF } from 'jspdf';
import QRCode from 'react-qr-code';
import { Download, FileText, Loader2 } from 'lucide-react';

export function ProjectPDFExportButton({ project, creadorNombre }) {
    const [isExporting, setIsExporting] = useState(false);
    const pdfTemplateRef = useRef(null);

    // Filter Canvas blocks specifically for PDF (text and select images)
    // The user requested to KEEP everything, so we will map all blocks.
    const validBlocks = project?.canvas?.filter(b => b.content && (b.type === 'text' || b.type === 'image')) || [];

    // Public URL for the QR code
    const publicUrl = typeof window !== 'undefined' ? `${window.location.origin}/showcase` : 'https://integradorhub.com';

    const handleExportPDF = async () => {
        if (!pdfTemplateRef.current || !project) return;

        setIsExporting(true);
        try {
            // Give normal DOM a moment to ensure all images in the hidden div are loaded
            await new Promise(res => setTimeout(res, 800));

            const canvas = await html2canvas(pdfTemplateRef.current, {
                scale: 2, // higher resolution
                useCORS: true, // allow external images
                allowTaint: true,
                logging: false,
                windowWidth: 800 // mimic a stable width
            });

            const imgData = canvas.toDataURL('image/jpeg', 0.95); // Slight compression

            // A4 measures 210mm x 297mm
            const pdf = new jsPDF('p', 'mm', 'a4');
            const pdfWidth = pdf.internal.pageSize.getWidth();
            const pdfHeight = (canvas.height * pdfWidth) / canvas.width;

            // Simple pagination logic for tall canvases
            let heightLeft = pdfHeight;
            let position = 0;

            pdf.addImage(imgData, 'JPEG', 0, position, pdfWidth, pdfHeight);
            heightLeft -= pdf.internal.pageSize.getHeight();

            while (heightLeft > 0) { // Fix >= to > to avoid blank extra page
                position = heightLeft - pdfHeight;
                pdf.addPage();
                pdf.addImage(imgData, 'JPEG', 0, position, pdfWidth, pdfHeight);
                heightLeft -= pdf.internal.pageSize.getHeight();
            }

            pdf.save(`Proyecto_${project.titulo?.replace(/\s+/g, '_') || 'Export'}.pdf`);
        } catch (error) {
            console.error('Error exportando PDF:', error);
            alert(`Hubo un error al generar el PDF: ${error.message || error}`);
        } finally {
            setIsExporting(false);
        }
    };

    if (!project) return null;

    return (
        <>
            {/* The Trigger Button */}
            <button
                onClick={handleExportPDF}
                disabled={isExporting}
                className="flex items-center justify-center gap-2 px-4 py-2 bg-gray-900 text-white text-sm font-bold rounded-xl shadow-md hover:bg-black transition-all disabled:opacity-70 disabled:cursor-wait"
            >
                {isExporting ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />}
                {isExporting ? 'Generando...' : 'Exportar PDF'}
            </button>

            {/* Hidden Template for PDF Generation */}
            <div className="absolute top-[-9999px] left-[-9999px] w-[800px]">
                <div
                    ref={pdfTemplateRef}
                    className="p-12 pdf-template-container"
                    style={{ width: '800px', minHeight: '1120px', position: 'relative', backgroundColor: '#ffffff', color: '#111827' }} // A4 aspect-ratio approximation
                >
                    <style>{`
                        .pdf-template-container * {
                            border-color: #e5e7eb !important;
                            color: inherit;
                        }
                        .pdf-template-container .prose * {
                            color: #374151 !important;
                        }
                    `}</style>

                    {/* Brand / Header */}
                    <div className="flex justify-between items-start pb-8 mb-8" style={{ borderBottomWidth: '2px', borderBottomStyle: 'solid', borderBottomColor: '#f3f4f6' }}>
                        <div>
                            <h1 className="text-4xl font-extrabold tracking-tight mb-2" style={{ color: '#111827' }}>
                                {project.titulo || 'Sin Título'}
                            </h1>
                            <div className="font-medium text-lg flex items-center gap-2" style={{ color: '#6b7280' }}>
                                📄 {project.materia} • Ciclo {project.ciclo}
                            </div>
                        </div>
                        <div className="flex flex-col items-end gap-3 text-right">
                            <div className="p-3 rounded-xl shadow-sm" style={{ width: '116px', height: '116px', backgroundColor: '#f9fafb', borderWidth: '1px', borderStyle: 'solid', borderColor: '#e5e7eb' }}>
                                <QRCode value={publicUrl} size={90} level="H" viewBox={`0 0 256 256`} fgColor="#000000" bgColor="#f9fafb" />
                            </div>
                            <span className="text-xs font-bold uppercase tracking-wider" style={{ color: '#9ca3af' }}>
                                Escanea para ver en línea
                            </span>
                        </div>
                    </div>

                    {/* Metadata: Leader & Team */}
                    <div className="grid grid-cols-2 gap-8 mb-10">
                        <div className="p-6 rounded-2xl" style={{ backgroundColor: '#eff6ff', borderWidth: '1px', borderStyle: 'solid', borderColor: '#dbeafe' }}>
                            <h3 className="text-xs font-bold uppercase tracking-wider mb-2" style={{ color: '#3b82f6' }}>Responsable</h3>
                            <p className="text-xl font-bold" style={{ color: '#1f2937' }}>{creadorNombre}</p>
                            <p className="text-sm font-medium mt-1" style={{ color: '#6b7280' }}>Líder de Proyecto</p>
                        </div>
                        <div className="p-6 rounded-2xl" style={{ backgroundColor: '#f9fafb', borderWidth: '1px', borderStyle: 'solid', borderColor: '#f3f4f6' }}>
                            <h3 className="text-xs font-bold uppercase tracking-wider mb-2" style={{ color: '#6b7280' }}>Tecnologías Principales</h3>
                            <div className="flex flex-wrap gap-2">
                                {project.stackTecnologico?.length > 0 ? (
                                    project.stackTecnologico.map((tech, i) => (
                                        <span key={i} className="px-3 py-1 rounded-md text-sm font-bold shadow-sm" style={{ backgroundColor: '#ffffff', borderWidth: '1px', borderStyle: 'solid', borderColor: '#e5e7eb', color: '#4b5563' }}>
                                            {tech}
                                        </span>
                                    ))
                                ) : (
                                    <span className="text-sm" style={{ color: '#9ca3af' }}>No especificado</span>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Team Members */}
                    {project.members && project.members.length > 0 && (
                        <div className="mb-10">
                            <h3 className="text-lg font-bold pb-2 mb-4" style={{ color: '#1f2937', borderBottomWidth: '1px', borderBottomStyle: 'solid', borderBottomColor: '#f3f4f6' }}>Equipo Acópsula (Squad)</h3>
                            <div className="flex flex-wrap gap-4">
                                {project.members.map((m, idx) => (
                                    <div key={idx} className="flex items-center gap-2 px-4 py-2 rounded-full" style={{ backgroundColor: '#f9fafb', borderWidth: '1px', borderStyle: 'solid', borderColor: '#f3f4f6' }}>
                                        <div style={{ width: '24px', height: '24px', lineHeight: '24px', textAlign: 'center', borderRadius: '50%', backgroundColor: '#e0e7ff', color: '#4338ca', fontWeight: 'bold', fontSize: '12px', display: 'inline-block' }}>
                                            {(m.nombre || 'U')[0].toUpperCase()}
                                        </div>
                                        <span className="text-sm font-semibold" style={{ color: '#374151' }}>
                                            {m.nombre && m.nombre !== 'Usuario' ? m.nombre : m.email}
                                        </span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Canvas Content (Description & Images) */}
                    <div className="mt-8">
                        <h3 className="text-lg font-bold pb-2 mb-6" style={{ color: '#1f2937', borderBottomWidth: '1px', borderBottomStyle: 'solid', borderBottomColor: '#f3f4f6' }}>Detalles del Proyecto</h3>
                        <div className="space-y-6">
                            {validBlocks.length > 0 ? (
                                validBlocks.map((block, idx) => {
                                    if (block.type === 'text') {
                                        return (
                                            <div
                                                key={idx}
                                                // Retain prose for sizing, but colors handled by style tag
                                                className="prose prose-sm max-w-none leading-relaxed"
                                                dangerouslySetInnerHTML={{ __html: block.content }}
                                            />
                                        );
                                    } else if (block.type === 'image') {
                                        return (
                                            <div key={idx} className="my-6 rounded-xl overflow-hidden shadow-sm" style={{ borderWidth: '1px', borderStyle: 'solid', borderColor: '#f3f4f6' }}>
                                                <img
                                                    src={block.content}
                                                    alt="Project visualization"
                                                    className="w-full h-auto object-contain max-h-[500px]"
                                                />
                                            </div>
                                        );
                                    }
                                    return null;
                                })
                            ) : (
                                <p className="italic" style={{ color: '#9ca3af' }}>No hay contenido documentado todavía.</p>
                            )}
                        </div>
                    </div>

                    {/* Footer */}
                    <div className="absolute bottom-12 left-12 right-12 text-center pt-6" style={{ borderTopWidth: '1px', borderTopStyle: 'solid', borderTopColor: '#f3f4f6' }}>
                        <p className="text-sm font-medium" style={{ color: '#9ca3af' }}>
                            Generado automáticamente por Byfrost • IntegradorHub
                        </p>
                    </div>
                </div>
            </div>
        </>
    );
}
