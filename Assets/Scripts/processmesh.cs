using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class processmesh : MonoBehaviour
{
	public float PositionAmplifier = 10.0f;
	public static float GetCurvature(Vector3 n1, Vector3 n2, Vector3 p1, Vector3 p2, float positionAmplifier)
	{
		p1 *= positionAmplifier;
		p2 *= positionAmplifier;
		n1 = n1.normalized;
		n2 = n2.normalized;
		float v1 =(Mathf.Pow((p1 - p2).magnitude, 2));
		float v2 = (Vector3.Dot((n1 - n2), (p1 - p2)));
		return v2 / v1;
	}


	public static void AddToDic(Dictionary<int, List<float>> dic, int index, float v)
	{
		if (!dic.ContainsKey(index))
		{
			dic.Add(index, new List<float>());
		}
		dic[index].Add(v);
	}

	public static void ProcessMesh(Mesh m, float positionAmplifier)
	{
		Dictionary<int, List<float>> dic = new Dictionary<int, List<float>>();

		int[] tris = m.triangles;
		Vector3[] normals = m.normals;
		Vector3[] verts = m.vertices;
		for (int i = 0; i < tris.Length; i += 3)
		{
			int index1 = tris[i], index2 = tris[i + 1], index3 = tris[i + 2];

			float cur1 = GetCurvature(normals[index1], normals[index2], verts[index1], verts[index2], positionAmplifier);
			float cur2 = GetCurvature(normals[index2], normals[index3], verts[index2], verts[index3], positionAmplifier);
			float cur3 = GetCurvature(normals[index3], normals[index1], verts[index3], verts[index1], positionAmplifier);

			AddToDic(dic, index1, cur1);
			AddToDic(dic, index1, cur3);

			AddToDic(dic, index2, cur1);
			AddToDic(dic, index2, cur2);

			AddToDic(dic, index3, cur2);
			AddToDic(dic, index3, cur3);
		}

		Vector2[] uv2 = new Vector2[verts.Length];
		double max = 0;
		for (int i = 0; i < verts.Length; i++)
		{
			List<float> l = dic[i];
			double v = 1;
			for (int j = 0; j < l.Count; j++)
				v *= Mathf.Abs(l[j]);

			v = System.Math.Pow(v, 1f / l.Count);
			max = v > max ? v : max;
			uv2[i] = new Vector2((float)v, (float)v);
		}


		/*
		for(int i = 0; i < verts.Length; i++)
        {
			uv2[i] = uv2[i] / (float)max;
        }
		*/

		m.uv2 = uv2;

	}

	// Start is called before the first frame update
	void Start()
    {
		MeshFilter mf = GetComponent<MeshFilter>();
		ProcessMesh(mf.mesh, PositionAmplifier);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
