using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(DebugRenderer), PostProcessEvent.AfterStack, "Custom/Debug")]
public sealed class Debug : PostProcessEffectSettings
{
    public IntParameter maxIterations = new IntParameter { value = 64 };
    public FloatParameter maxDistance = new FloatParameter { value = 100f };
    public FloatParameter minDistance = new FloatParameter { value = 0.01f };

    public DepthTextureMode GetCameraFlags()
    {
        return DepthTextureMode.Depth; //| DepthTextureMode.DepthNormals;
    }
}

public sealed class DebugRenderer : PostProcessEffectRenderer<Debug>
{
    public override void Render(PostProcessRenderContext context)
    {
        Camera _cam = context.camera;

        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Debug"));
        sheet.properties.SetMatrix("_CamFrustum", FrustumCorners2(_cam));
        sheet.properties.SetMatrix("_CamToWorld", _cam.cameraToWorldMatrix);
        sheet.properties.SetVector("_CamWorldSpace", _cam.transform.position);
        sheet.properties.SetInt("_MaxIterations", settings.maxIterations);
        sheet.properties.SetFloat("_MaxDistance", settings.maxDistance);
        sheet.properties.SetFloat("_MinDistance", settings.minDistance);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
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

    private Matrix4x4 GetFrustumCorners(Camera cam)
    {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = camFov * 0.5f;

        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        return frustumCorners;
    }

    private Matrix4x4 FrustumCorners(Camera cam)
    {
        Transform camtr = cam.transform;
        Vector3[] frustumCorners = new Vector3[4];
        cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1), cam.farClipPlane, cam.stereoActiveEye, frustumCorners);
        var bottomLeft = camtr.TransformVector(frustumCorners[0]);
        var topLeft = camtr.TransformVector(frustumCorners[1]);
        var topRight = camtr.TransformVector(frustumCorners[2]);
        var bottomRight = camtr.TransformVector(frustumCorners[3]);

        Matrix4x4 frustumCornersArray = Matrix4x4.identity;
        frustumCornersArray.SetRow(0, bottomLeft);
        frustumCornersArray.SetRow(1, bottomRight);
        frustumCornersArray.SetRow(2, topLeft);
        frustumCornersArray.SetRow(3, topRight);

        return frustumCornersArray;
    }

    private Matrix4x4 FrustumCorners2(Camera cam)
    {
        Transform camtr = cam.transform;

        Vector3[] frustumCorners = new Vector3[4];
        cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1),
         cam.farClipPlane, cam.stereoActiveEye, frustumCorners);
        var bottomLeft = camtr.TransformVector(frustumCorners[1]);
        var topLeft = camtr.TransformVector(frustumCorners[0]);
        var bottomRight = camtr.TransformVector(frustumCorners[2]);

        Matrix4x4 frustumVectorsArray = Matrix4x4.identity;
        frustumVectorsArray.SetRow(0, bottomLeft);
        frustumVectorsArray.SetRow(1, bottomLeft + (bottomRight - bottomLeft) * 2);
        frustumVectorsArray.SetRow(2, bottomLeft + (topLeft - bottomLeft) * 2);

        return frustumVectorsArray;
    }
}