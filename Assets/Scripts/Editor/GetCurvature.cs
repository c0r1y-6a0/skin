using UnityEngine;
using UnityEditor;

public class GetCurvature 
{
    [MenuItem("Assets/计算曲率并写入mesh的uv2")]
    static void DoIt()
    {
        foreach(var guid in Selection.assetGUIDs)
        {
            var go = AssetDatabase.LoadAssetAtPath(AssetDatabase.GUIDToAssetPath(guid), typeof(GameObject)) as GameObject;
            foreach(var mf in go.GetComponentsInChildren<MeshFilter>())
            {
                var mesh = mf.sharedMesh;
                processmesh.ProcessMesh(mesh, 1);
                EditorUtility.SetDirty(mesh);
            }
            EditorUtility.SetDirty(go);
        }
        AssetDatabase.SaveAssets();
    }
}