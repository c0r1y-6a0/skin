using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


public class QualityMgrWindow : EditorWindow
{
    [MenuItem("Tools/Quality Mgr")]
    static void ShowEditor()
    {
        QualityMgrWindow window = GetWindow<QualityMgrWindow>("QualityMgr");
        window.Show();
    }

    private bool m_lod100 = false;
    private void OnGUI()
    {
        EditorGUILayout.BeginVertical();
        m_lod100 = EditorGUILayout.Toggle("LOD100",m_lod100);
        Shader.globalMaximumLOD = m_lod100 ? 100 : 500;

        EditorGUILayout.EndVertical();
    }
}
