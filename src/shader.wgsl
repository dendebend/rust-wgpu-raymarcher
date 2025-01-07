struct VertexInput {
    @location(0) position: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

// Constants
const MAX_STEPS: i32 = 50;
const MAX_DIST: f32 = 100.0;
const SURF_DIST: f32 = 0.001;
const TAU: f32 = 6.283185;
const PI: f32 = 3.141592;
const MAT_OBJ: i32 = 1;
const MAT_BACK: i32 = 2;

@group(0) @binding(0) var<uniform> time: f32;

fn palette(t: f32) -> vec3<f32> {
    return 0.5 + 0.4 * sin(6.28318 * (t + vec3<f32>(1.4, 2.33, 0.57)));
}

fn Rot(a: f32) -> mat2x2<f32> {
    let s = sin(a);
    let c = cos(a);
    return mat2x2<f32>(c, s, -s, c);
}

fn sdGyroid(p: vec3<f32>, scale: f32, thickness: f32, bias: f32) -> f32 {
    var pScaled = p * scale;
    return (abs(dot(sin(pScaled), cos(vec3<f32>(pScaled.z, pScaled.x, pScaled.y))) - bias) / scale) - thickness;
}

fn sdLink(p: vec3<f32>, le: f32, r1: f32, r2: f32) -> f32 {
    let q = vec3<f32>(p.x, max(abs(p.y) - le, 0.0), p.z);
    return length(vec2<f32>(length(vec2<f32>(q.x, q.y)) - r1, q.z)) - r2;
}

fn GetDist(p: vec3<f32>) -> vec2<f32> {
    let a = sin(time);
    let a1 = cos(time * 0.05);
    var pMod = p;
    pMod.x += time * 4.0;
    
    let pSin = sin(pMod);
    var pClo = vec3<f32>(
        sin(pMod.z) + abs(0.5 * a + 0.5),
        cos(pMod.x) + abs(0.5 * a + 0.5),
        sin(pMod.y) + abs(0.5 * a + 0.5)
    );
    
    // Rotate pClo
    let rot = Rot(time * 2.0);
    let pCloXZ = pClo.xz * rot;
    pClo = vec3<f32>(pCloXZ.x, pClo.y, pCloXZ.y);
    
    let link = sdLink(pClo, sin(time) * 0.1, 0.7, 0.25);
    let gyr = sdGyroid(pSin - vec3<f32>(abs(a1 * 0.17)), 0.2, 0.012, 0.5);
    let sph = length(pClo) - 0.4;
    
    var d = min(sph, link);
    var mat: i32;
    
    if (d == link) {
        mat = MAT_BACK;
    } else {
        mat = MAT_OBJ;
    }
    
    return vec2<f32>(d, f32(mat));
}

fn RayMarch(ro: vec3<f32>, rd: vec3<f32>) -> f32 {
    var dO: f32 = 0.0;
    
    for(var i: i32 = 0; i < MAX_STEPS; i++) {
        let p = ro + rd * dO;
        let dS = GetDist(p).x;
        dO += dS;
        if(dO > MAX_DIST || abs(dS) < SURF_DIST) {
            break;
        }
    }
    
    return dO;
}

fn GetNormal(p: vec3<f32>) -> vec3<f32> {
    let e = vec2<f32>(0.001, 0.0);
    let n = GetDist(p).x - vec3<f32>(
        GetDist(p - vec3<f32>(e.x, e.y, e.y)).x,
        GetDist(p - vec3<f32>(e.y, e.x, e.y)).x,
        GetDist(p - vec3<f32>(e.y, e.y, e.x)).x
    );
    
    return normalize(n);
}

@vertex
fn vs_main(input: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = vec4<f32>(input.position, 0.0, 1.0);
    out.uv = input.position;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    
    // Camera setup
    var ro = vec3<f32>(0.0, 1.0, 1.0);
    let rd = normalize(vec3<f32>(uv.x, uv.y, 1.0));
    
    var col = vec3<f32>(0.0);
    let d = RayMarch(ro, rd);
    
    if(d < MAX_DIST) {
        let p = ro + rd * d;
        let n = GetNormal(p);
        let dif = dot(n, normalize(vec3<f32>(1.0, 2.0, 3.0))) * 0.5 + 0.5;
        
        let mat = i32(GetDist(p).y);
        
        if(mat == MAT_BACK) {
            col = abs(vec3<f32>(
                n.x + (fract(time * 0.3)),
                n.y * 1.1,
                n.z * 12.55205
            ));
            col += abs(dif * dif) / (time * 0.4);
            col -= pow(dif, sin(time * 0.3));
        } else if(mat == MAT_OBJ) {
            col = vec3<f32>(
                n.x * 0.3 + sin(time),
                (n.y * 2.0) - cos(time),
                n.z * (-1.55205)
            );
            col += sin(abs(dif * dif) + 1.5);
            col -= pow(dif, -1.0);
        }
    }
    
    return vec4<f32>(col, 2.0);
}
