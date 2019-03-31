using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class fractal : SceneViewFilter
{
    [SerializeField]
    private Shader _shader;

    public Material _raymarchMaterial
    {
        get
        {
            if (!_raymarchMat && _shader)
            {
                _raymarchMat = new Material(_shader);
                _raymarchMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return _raymarchMat;
        }
    }

    private Material _raymarchMat;

    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }
            return _cam;
        }
    }
    private Camera _cam;
    [Header("Set Up")]
    [Range(1, 500)]
    public float _maxDistance;
    [Range(1, 300)]
    public int _MaxIterations;
    [Range(0.01f, 0.0001f)]
    public float _accuracy;

    [Header("Directional Light")]
    public Transform _directionalLight;
    public Color _lightColor;
    [Range(0, 1)]
    public float _lightIntensity;

    [Header("Shading")]
    [Range(0, 1)]
    public float _shadowIntensity;
    public Vector2 _shadowDistance;
    [Range(0, 1)]
    public int _softShadow;
    [Range(1, 128)]
    public float _ShadowPenumbra;

    [Header("Ambient Occlusion")]
    [Range(0.01f, 10.0f)]
    public float _aoStepSize;
    [Range(1, 5)]
    public float _aoIterations;
    [Range(0, 1)]
    public float _aoIntensity;

    [Header("Color")]
    public Color _mainColor;
    public Color _shadowColor;
    public Color _secondColor, _backgroundColor;

    [Header("Signed Distance Field")]
    public Vector4 _sphere1;
    public Vector4 _box1;
    [Range(-5, 5)]
    public float _box1round;
    public Vector4 _sphere2;
    public Vector4 _box2;
    [Range(0, 1)]

    [Header("Magic")]
    public int _mod;
    public Vector3 _modInterval;
    [Range(-5, 5)]
    public float _smoothThresh1;
    [Range(-5, 5)]
    public float _smoothThresh2;
    [Range(0, 10)]
    public float _twist;



    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!_raymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        _raymarchMaterial.SetInt("_MaxIterations", _MaxIterations);
        _raymarchMaterial.SetFloat("_accuracy", _accuracy);
        _raymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        _raymarchMaterial.SetColor("_lightCol", _lightColor);
        _raymarchMaterial.SetColor("_secondColor", _secondColor);
        _raymarchMaterial.SetColor("_backgroundColor", _backgroundColor);
        _raymarchMaterial.SetMatrix("_CamToWorld", _camera.cameraToWorldMatrix);
        _raymarchMaterial.SetFloat("_MaxDistance", _maxDistance);
        _raymarchMaterial.SetFloat("_lightIntensity", _lightIntensity);
        _raymarchMaterial.SetFloat("_shadowIntensity", _shadowIntensity);
        _raymarchMaterial.SetFloat("_ShadowPenumbra", _ShadowPenumbra);
        _raymarchMaterial.SetVector("_shadowDistance", _shadowDistance);
        _raymarchMaterial.SetInt("_isSoftShadow", _softShadow);
        _raymarchMaterial.SetInt("_isMod", _mod);
        _raymarchMaterial.SetVector("_modInterval", _modInterval);
        _raymarchMaterial.SetVector("_sphere1", _sphere1);
        _raymarchMaterial.SetVector("_box1", _box1);
        _raymarchMaterial.SetFloat("_box1round", _box1round);
        _raymarchMaterial.SetVector("_sphere2", _sphere2);
        _raymarchMaterial.SetVector("_box2", _box2);
        _raymarchMaterial.SetFloat("_thresh1", _smoothThresh1);
        _raymarchMaterial.SetFloat("_thresh2", _smoothThresh2);
        _raymarchMaterial.SetFloat("_twist", _twist);
        _raymarchMaterial.SetVector("_lightDirection", _directionalLight ? _directionalLight.forward : Vector3.down);
        _raymarchMaterial.SetColor("_mainColor", _mainColor);
        _raymarchMaterial.SetColor("_shadowColor", _shadowColor);
        _raymarchMaterial.SetFloat("_aoStepSize", _aoStepSize);
        _raymarchMaterial.SetFloat("_aoIterations", _aoIterations);
        _raymarchMaterial.SetFloat("_aoIntensity", _aoIntensity);

        RenderTexture.active = destination;
        _raymarchMaterial.SetTexture("_MainTex", source);
        GL.PushMatrix();
        GL.LoadOrtho();
        _raymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);

        return frustum;
    }
    private void Start()
    {
        //transform = new Vector3();
    }
    private void Update()
    {
        //transform.RotateAround(Vector3.zero, Vector3.up, 20 * Time.deltaTime);
        //_box1.w = Mathf.Sin(Time.time * 2) * 2.5f + 5.5f;
        //_sphere1.w = Mathf.Sin(Mathf.Exp(Mathf.Cos(Time.time * 0.8f))*2f) + 2.5f;
        //_sphere1.z = Mathf.Sin(Time.time * 2) * 5.5f;
        //_twist = Mathf.Cos(Time.time * 3) * 2f + 2f;
    }
}