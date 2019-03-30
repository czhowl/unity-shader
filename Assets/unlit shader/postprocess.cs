using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class postprocess : MonoBehaviour {

	public Material mat;

	void OnRenderImage( RenderTexture src, RenderTexture dest) {
	
	
		Graphics.Blit (src, dest, mat);
	}

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
