------------
-- PICO-TweenMachine -
-- An additional small extension
-- library for PICO-Tween that
-- acts as a wrapper, powering
-- all tween related functionality
-- internally, rather than having
-- large chunks of tweening 
-- cluttering the codebase.
--
-- @script PICO-TweenMachine
-- @author Joeb Rogers
-- @license MIT
-- @copyright Joeb Rogers 2018

tween_machine = {
    instances = {}
}
function tween_machine:update()
    for t in all(self.instances) do
        t:update()
    end
end

function tween_machine:add_tween(instance)
    setmetatable(instance, {__index = __tween})
    add(self.instances, instance)
    instance:init()
    return instance
end

__tween = {
    func = nil,
    v_start = 0,
    v_end = 1,
    value = 0,
    start_time = 0,
    duration = 0,
    elapsed,
    finished = false,

    --- Callbacks
    -- Will pass through value
    -- as argument.
    step_callbacks = {},
    -- Will pass through tween
    -- object as argument.
    finished_callbacks = {}
}

function __tween:register_step_callback(func)
    add(self.step_callbacks, func)
end

function __tween:register_finished_callback(func)
    add(self.finished_callbacks, func)
end

function __tween:init()
    self.start_time = time()
    self.value = self.v_start
end

function __tween:restart()
    self:init()
    self.elapsed = 0
    self.finished = false
end

function __tween:update()
    if (self.finished) return

    self.elapsed = time() - self.start_time
    if (self.elapsed > self.duration) self.elapsed = self.duration
    self.value = self.func(
        self.elapsed, 
        self.v_start, 
        self.v_end - self.v_start,
        self.duration
    )

    if #self.step_callbacks > 0 then
        for v in all(self.step_callbacks) do
            v(self.value)
        end
    end

    local progress = self.elapsed / self.duration
    if (progress >= 1) then 
        self.finished = true
        if #self.finished_callbacks > 0 then
            for v in all(self.finished_callbacks) do
                v(self)
            end
        end
    end
end

function __tween:remove()
    del(tween_machine.instances, self)
end