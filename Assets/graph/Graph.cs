using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Graph : MonoBehaviour {

	public Transform pointPrefab;
	[Range(10, 1000)]
	public int resolution = 1000;

	Transform[] points;
	Transform[] points2;

	// Use this for initialization
	void Awake () {
		
		float step = 4f / resolution;
		Vector3 scale = Vector3.one * 0.4f;
		Vector3 position;
		position.y = 0f;
		position.z = 0f;
		points = new Transform[resolution];
		for (int i = 0; i < points.Length; i++) {
			Transform point = Instantiate(pointPrefab);
			position.x = (i + 0.5f) * step - 2f;
			point.localPosition = position;
			point.localScale = scale;
			point.SetParent(transform, false);
			points[i] = point;
		}
		points2 = new Transform[resolution];
		for (int i = 0; i < points2.Length; i++) {
			Transform point = Instantiate(pointPrefab);
			position.x = (i + 0.5f) * step - 2f;
			point.localPosition = position;
			point.localScale = scale;
			point.SetParent(transform, false);
			points2[i] = point;
		}
	}
	
	// Update is called once per frame
	void Update () {
		for (int i = 0; i < points.Length; i+=2) {
			Transform point = points[i];
			Vector3 position = point.localPosition;
			position.y = Mathf.Sin(Mathf.PI * (position.x + Time.time));
			point.localPosition = position;
		}
		for (int i = 1; i < points.Length; i+=2) {
			Transform point = points[i];
			Vector3 position = point.localPosition;
			position.y = Mathf.Cos(Mathf.PI * (position.x + Time.time));
			point.localPosition = position;
		}
		for (int i = 0; i < points2.Length; i+=2) {
			Transform point = points2[i];
			Vector3 position = point.localPosition;
			position.y = Mathf.Sin(Mathf.PI * (position.x + Time.time) + Mathf.PI);
			point.localPosition = position;
		}
		for (int i = 1; i < points2.Length; i+=2) {
			Transform point = points2[i];
			Vector3 position = point.localPosition;
			position.y = Mathf.Cos(Mathf.PI * (position.x + Time.time) + Mathf.PI);
			point.localPosition = position;
		}
	}
}
