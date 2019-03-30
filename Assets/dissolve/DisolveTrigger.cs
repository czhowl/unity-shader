using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DisolveTrigger : MonoBehaviour {

	public Material disolveMat;
	public float speed = 1;

	private float thresh = 1, startTime = 0;

	// Use this for initialization
	void Start () {
        startTime = Time.time;
        thresh = 1;
    }
	
	// Update is called once per frame
	void Update () {
		//if(thresh >= 0){
		//	disolveMat.SetFloat ("_DisolveThresh", thresh);
  //          thresh -= Time.deltaTime * speed;
		//}

        //thresh = Mathf.Sin(Time.time * speed)/2f + 0.5f;
        //disolveMat.SetFloat("_DisolveThresh", thresh);

        thresh = Mathf.Sin(Time.time * speed) * 2f + 1f;
        disolveMat.SetFloat("_DissolveAmount", thresh);

        if (Input.GetKeyDown (KeyCode.E))
			triggerEffect ();
	}

	private void triggerEffect(){
		startTime = Time.time;
        thresh = 1;
	}

}
