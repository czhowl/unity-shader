// Sphere
// s: radius
float maxcomp(float2 p)
{
  return max(p.x, p.y);
}

float sdSphere(float3 p, float s)
{ 
    return length(p) - s;
}

//float DE(float3 z)
//{
//  z.xy = fmod((z.xy),1.0)-float3(0.5,0.5,0.5); // instance on xy-plane
//  return length(z)-0.3;             // sphere DE
//}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdRoundBox( in float3 p, in float3 b, in float r ) 
{
    float3 q = abs(p) - b;
    return min(max(q.x,max(q.y,q.z)),0.0) + length(max(q,0.0)) - r;
}

float sdTorus(float3 p, float2 t )
{
  float2 q = float2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdPlane( float3 p, float4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}


// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); 
}

float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h);
}

float3 opTwist( inout float3 p, float k )
{
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    float2x2  m = {c,-s,s,c};
    float3  q= float3(mul(m,p.xz),p.y);
    return q;
}

//float3 map( in float3 p )
//{
//    float d = sdBox(p,float3(1.0, 1.0, 1.0));
//    return float3(d,0.0,0.0);
//}


//float sdCross( in float3 p )
//{
//  float da = sdBox(p.xyz, float3(1.#INF,1.0,1.0));
//  float db = sdBox(p.yzx, float3(1.0,1.#INF,1.0));
//  float dc = sdBox(p.zxy, float3(1.0,1.0,1.#INF));
//  return min(da,min(db,dc));
//}

float sdCross( in float3 p )
{
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.zx));
  return min(da,min(db,dc))-1.0;
}

//float4 map( in float3 p )
//{
//   float d = sdBox(p,float3(1.0,1.0,1.0));
//   float c = sdCross(p*3.0)/3.0;
//   d = max( d, -c );
//   return float4(d,1.0,1.0,1.0);
//}

float4 map( in float3 p )
{
   float d = sdBox(p-float3(.5,.5,.5),float3(3.0,3.0,3.0));
   float s = 1.0;
  float3 a = fmod( p*s, 2.0 )-1.0;
      s *= 3.0;
      float3 r = 1.0 - 3.0*abs(a);

      float c = sdCross(r)/s;
      d = max( d, -c );
   return float4(c,1.0,1.0,1.0);
}

float sdOctahedron( in float3 p, in float s)
{
    p = abs(p);
    float m = p.x+p.y+p.z-s;
    float3 q;
         if( 3.0*p.x < m ) q = p.xyz;
    else if( 3.0*p.y < m ) q = p.yzx;
    else if( 3.0*p.z < m ) q = p.zxy;
    else return m*0.57735027;
    
    float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
    return length(float3(q.x,q.y-s+k,q.z-k)); 
}
