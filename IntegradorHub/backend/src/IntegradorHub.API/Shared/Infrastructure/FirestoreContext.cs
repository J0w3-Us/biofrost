using Google.Cloud.Firestore;

namespace IntegradorHub.API.Shared.Infrastructure;

public class FirestoreContext
{
    private static FirestoreDb? _db;
    private static readonly object _lock = new();
    
    public static FirestoreDb GetDatabase()
    {
        if (_db is null)
        {
            lock (_lock)
            {
                if (_db is null)
                {
                    // Set credentials path
                    var credentialsPath = Path.Combine(
                        Directory.GetCurrentDirectory(), 
                        "..", "..", "..",
                        "integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json"
                    );
                    
                    if (File.Exists(credentialsPath))
                    {
                        Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", credentialsPath);
                    }
                    
                    var projectId = Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID") 
                                    ?? "integradorhub-dsm";
                    
                    _db = FirestoreDb.Create(projectId);
                }
            }
        }
        
        return _db;
    }
    
    // Colecciones
    public static CollectionReference Users => GetDatabase().Collection("users");
    public static CollectionReference Projects => GetDatabase().Collection("projects");
    public static CollectionReference Groups => GetDatabase().Collection("groups");
    public static CollectionReference Materias => GetDatabase().Collection("materias");
    public static CollectionReference Evaluations => GetDatabase().Collection("evaluations");
}
