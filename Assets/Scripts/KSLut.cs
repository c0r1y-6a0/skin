using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KSLut: MonoBehaviour
{
    public int LutWidth;
    public int LutHeight;
    public Material Mat;

    public void CreateKSLUT()
    {
        Texture2D lutTex = new Texture2D(LutWidth, LutHeight, TextureFormat.ARGB32, false);

        RenderTexture rt = new RenderTexture(LutWidth, LutHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        Graphics.Blit(null, rt, Mat);
        RenderTexture.active = rt;
        lutTex.ReadPixels(new Rect(0, 0, LutWidth, LutHeight), 0, 0, false);
        System.IO.File.WriteAllBytes(Application.dataPath + "/Lut.png", lutTex.EncodeToPNG());
    }

    public void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
            CreateKSLUT();
    }
}
