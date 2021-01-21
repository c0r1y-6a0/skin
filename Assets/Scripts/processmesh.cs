using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class processmesh : MonoBehaviour
{
	float GetCurvature(Vector3 n1, Vector3 n2, Vector3 p1, Vector3 p2)
	{
		float v1 =(Mathf.Pow((p1 - p2).magnitude, 2));
		float v2 = Mathf.Abs(Vector3.Dot((n1 - n2), (p1 - p2)));
		return v2 / v1;
	}


	void AddToDic(Dictionary<int, List<float>> dic, int index, float v)
	{
		if (!dic.ContainsKey(index))
		{
			dic.Add(index, new List<float>());
		}
		dic[index].Add(v);
	}

	void ProcessMesh(Mesh m)
	{
		Dictionary<int, List<float>> dic = new Dictionary<int, List<float>>();

		int[] tris = m.triangles;
		Vector3[] normals = m.normals;
		Vector3[] verts = m.vertices;
		for (int i = 0; i < tris.Length; i += 3)
		{
			int index1 = tris[i], index2 = tris[i + 1], index3 = tris[i + 2];

			float cur1 = GetCurvature(normals[index1], normals[index2], verts[index1], verts[index2]);
			float cur2 = GetCurvature(normals[index2], normals[index3], verts[index2], verts[index3]);
			float cur3 = GetCurvature(normals[index3], normals[index1], verts[index3], verts[index1]);

			AddToDic(dic, index1, cur1);
			AddToDic(dic, index1, cur3);

			AddToDic(dic, index2, cur1);
			AddToDic(dic, index2, cur2);

			AddToDic(dic, index3, cur2);
			AddToDic(dic, index3, cur3);
		}

		Vector2[] uv2 = new Vector2[verts.Length];
		for (int i = 0; i < verts.Length; i++)
		{
			List<float> l = dic[i];
			float v = 1;
			for (int j = 0; j < l.Count; j++)
				v *= l[j];

			v = Mathf.Abs(Mathf.Pow(v, 1f / l.Count));
			uv2[i] = new Vector2(v, v);
		}

		m.uv2 = uv2;
	}

	// Start is called before the first frame update
	void Start()
    {
		MeshFilter mf = GetComponent<MeshFilter>();
		ProcessMesh(mf.mesh);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
