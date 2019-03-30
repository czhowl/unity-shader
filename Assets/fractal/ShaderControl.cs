using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderControl : MonoBehaviour
{
    public Material disolveMat;
    public float speed = 1;
    public bool disolve = false;
    private float thresh = 1, startTime = 0;
    // Use this for initialization
    void Start()
    {
        startTime = Time.time;
        thresh = 1;
    }

    // Update is called once per frame
    void Update()
    {
        //if(thresh >= 0){
        //  disolveMat.SetFloat ("_DisolveThresh", thresh);
        //          thresh -= Time.deltaTime * speed;
        //}

        //thresh = Mathf.Sin(Time.time * speed)/2f + 0.5f;
        //disolveMat.SetFloat("_DisolveThresh", thresh);

        //thresh = Mathf.Sin(Time.time * speed) * 2f + 1f;
        if (disolve == true)
        {
            thresh = Mathf.PerlinNoise(Time.time, 0.0f) / 3f + 0.9f;
            disolveMat.SetFloat("_DissolveAmount", thresh);
        }
        else
        {
            disolveMat.SetFloat("_DissolveAmount", -1f);
        }

        //if (Input.GetKeyDown(KeyCode.E))
        //triggerEffect();
    }

    static float SuperLerp(float value, float from, float to, float from2, float to2)
    {
        if (value <= from2)
            return from;
        else if (value >= to2)
            return to;
        return (to - from) * ((value - from2) / (to2 - from2)) + from;
    }
}
