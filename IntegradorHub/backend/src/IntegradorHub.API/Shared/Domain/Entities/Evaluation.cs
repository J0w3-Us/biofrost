using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Domain.Entities;

[FirestoreData]
public class Evaluation
{
    [FirestoreDocumentId]
    public string Id { get; set; } = string.Empty;
    
    [FirestoreProperty("project_id")]
    public string ProjectId { get; set; } = string.Empty;
    
    [FirestoreProperty("docente_id")]
    public string DocenteId { get; set; } = string.Empty;
    
    [FirestoreProperty("docente_nombre")]
    public string DocenteNombre { get; set; } = string.Empty;
    
    [FirestoreProperty("tipo")]
    public string Tipo { get; set; } = "sugerencia"; // "oficial" | "sugerencia"
    
    [FirestoreProperty("contenido")]
    public string Contenido { get; set; } = string.Empty;
    
    [FirestoreProperty("calificacion")]
    public int? Calificacion { get; set; } // Solo para tipo "oficial", 0-100

    [FirestoreProperty("es_publico")]
    public bool EsPublico { get; set; } = false; // Control de privacidad por el líder

    [FirestoreProperty("puntos_otorgados")]
    public int PuntosOtorgados { get; set; } = 0; // Valor numérico para sumas (10-100 o 10-50)
    
    [FirestoreProperty("created_at")]
    public Timestamp CreatedAt { get; set; }
    
    [FirestoreProperty("updated_at")]
    public Timestamp UpdatedAt { get; set; }
}
