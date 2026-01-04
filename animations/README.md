# Lib3DObjects – Animations

Lib3DObjects animations are implemented as **Object callbacks**.

That means there is no separate animation engine you have to register things with: an “animation” is just a function that gets executed every frame during `BaseObject:Update()`.

This folder contains factory helpers in `animations/animations.lua` that generate those callback functions.

---

## The core idea: animations run as callbacks

Objects have a callback list (`self.callbacks`). During `BaseObject:Update()` the library runs them like this:

- signature: `callback(object, distanceToPlayer, distanceToCamera)`
- callbacks are run after distance culling but before the renderer applies transforms
- if a callback returns `true`, the object removes that callback automatically

### “Run forever” vs “auto end”

You control animation lifetime by what the callback returns:

- **Return `true`** → the animation is finished and will be removed.
- **Return `false` or return nothing** → the animation continues and will run again next update.

(So “forever” animations typically just never return `true`.)

---

## How built-in animation factories are structured

Most functions in `lib.animations` are **factories**.

They usually return a *creator* function, and that creator function returns the actual per-frame callback.

The pattern looks like this:

- configure your animation (duration, amplitude, condition, …)
- call the creator to capture a `beginTime` / initial values
- add the produced callback via `object:AddCallback(callback)`

This is why many functions are shaped like:

- ```
    CreateSomething(...)
    -> returns function()  -- creator, captures start time
         return function(self, distanceToPlayer, distanceToCamera)
             ...per-frame work...
         end
       end
  ```
  

---

## Built-in animations and triggers (current implementation)

All live in `animations/animations.lua` under `lib.animations`.

### One-shot animations (end automatically)

These all compute a progress from `0..1` and return `true` when the duration has elapsed.

- `CreateSingleRotationAnimation(durationMS, pitchDegrees, yawDegrees, rollDegrees)`
  - Drives `self.rotation.animationOffsetPitch/Yaw/Roll` over time.

- `CreateSingleFadeAnimation(durationMS, fromAlpha, toAlpha)`
  - Drives `self.Control:SetAlpha(...)` over time.

- `CreateSingleScaleAnimation(durationMS, toScale)`
  - Tweens from the current object scale to `toScale` over time.

- `CreateSingleBounceAnimation(durationMS, frequency, amplitude)`
  - Bounces vertically by writing `self.position.animationOffsetY`.

### Continuous animations (run until a condition stops them)

These take an optional `conditionFunc`. If it returns falsy, the callback does nothing.

Because they don’t return `true`, they will keep running “forever” (until you remove the callback).

- `CreateContinuesBounceAnimation(conditionFunc, frequency, amplitude)`
- `CreateContinuesRotationAnimation(conditionFunc, frequency, pitchDegreesPerCycle, yawDegreesPerCycle, rollDegreesPerCycle)`
- `CreateContinuesPulseAnimation(conditionFunc, minAlpha, maxAlpha)`
- `CreateContinuesFlashAnimation(conditionFunc, offDuration, onDuration)`

### Triggers (callbacks that fire enter/leave events)

Triggers are also callback generators. They keep internal state (`fired`) to detect transitions.

They do not end automatically.

- `CreateRadiusTrigger(activationRadius, enterCallback, leaveCallback)`
  - Uses `distanceToPlayer`.

- `CreateRadiusTriggerForUnit(unitTag, activationRadius, enterCallback, leaveCallback)`
  - Computes distance to another unit.

- `CreateMouseOverTrigger(activationRadius, enterCallback, leaveCallback)`
  - Approximates “mouse over” in 3D by comparing object direction vs camera forward vector.

---

## Attaching animations to an object

You attach a callback/animation using:

- `object:AddCallback(callback)`

For the built-in factories, the common usage is:

1. create the callback (often by calling the returned creator)
2. add it to the object

Example pattern:

- `local animation = lib.animations.CreateSingleScaleAnimation(300, 2.0) -- factory call`
- `local preparedAnimation = animation()  -- call to get the per-frame callback with captured start time`
- `obj:AddCallback(preparedAnimation)  -- attach to object`

(Notice the `() ()` — first to get the creator, second to get the callback with captured start time.)

### Removing animations

You can remove callbacks manually:

- `object:RemoveCallback(preparedAnimation)`
- `object:RemoveAllCallbacks() -- watch out though! Some ObjectCLasses implement callbacks to function correctly, so removing all may break things.`

Or you let them remove themselves by returning `true`.

---

## Choosing what to animate (best practices)

Lib3DObjects has two places you can write animation state:

### 1) Prefer animation offsets (recommended)

- position: `self:SetAnimationOffset(X, Y, Z)`
- rotation: `self:SetAnimationRotationOffset(Pitch, Yaw, Roll)`

These offsets are automatically included by:

- `GetFullPosition()`
- `GetFullRotation()`

So you can animate without permanently changing the base transform.

### 2) Directly touching the control (use with care)

Some built-in animations set control properties directly (example: `Control:SetAlpha`).

That can be fine, but remember:

- `BaseObject:Update()` also applies distance-based fading and the object’s `self.alpha`.
- so “alpha animations” can conflict with distance fade if you’re not careful.

If you want a fade that plays nicely with the library’s fade logic, consider driving `self:SetAlpha(alpha)` instead of the control alpha.

Always try to use the builtin functions of the object where possible, so the library can manage state consistently. If you really need to manipulate the control directly, be aware of potential conflicts and make sure you undo the changes before destroying the object.

---

## Writing your own animation

An animation is just a callback function. Here’s the “contract” to follow:

- input: `(object, distanceToPlayer, distanceToCamera)`
- do your per-frame work
- return:
  - `true` to end, or
  - `false` / `nil` to keep running

### Simple one-shot example (move up for 500ms)

- On start: capture the start time and the original state.
- Each update: compute progress and update an animation offset.
- On finish: optionally snap to final state and return `true`.

### Continuous example (spin while enabled)

You can keep a `beginTime` and compute elapsed time, and simply never return `true`.

---

## Animations on destroy

`BaseObject:Destroy()` supports an optional “destroy animation” via:

- `object:SetOnDestroyAnimation(callback)`

When `Destroy()` is called:

- the on-destroy callback is added to the object’s callback list
- the object is only actually released back to the pool after the callback list becomes empty

So if your destroy animation returns `true` after (say) 300ms, the object will remain alive for that duration, and then be released. This also means that if your animation never returns `true`, the object will never be destroyed!

Tip: use animation offsets for destroy motion/rotation, and reset anything you changed in your object’s overridden `Destroy()` (because objects are pooled).
