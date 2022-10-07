// SOMEONE PLEASE REWRITE THIS!!!
// (this code really sucks)
// (please, someone, help me)

const gl = require("gl")
const THREE = require("three")
const fs = require("fs")

export interface Vector3 {
    x: number,
    y: number,
    z: number
}

export interface CFrame {
    position: Vector3,
    orientation: Vector3
}

export interface Color3 {
    r: number,
    g: number,
    b: number
}

export interface RobloxPart {
    cf: CFrame,
    size: Vector3,
    color: Color3
}

export interface RobloxScene {
    Parts: RobloxPart[],
    Camera: CFrame
}

// todo: MAYBE add spotlight/pointlight support and surfacelights too

export default function render_scene(scene:RobloxScene,filename:string) {
    
}