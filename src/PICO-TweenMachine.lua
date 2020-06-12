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

--- A table storing various utility
-- functions used by the ECS.
utilities = {}

--- Assigns the contents of a table to another.
-- Copy over the keys and values from source 
-- tables to a target. Assign only shallow copies
-- to the target table. For a deep copy, use
-- deep_assign instead.
-- @param target The table to be copied to.
-- @param source Either a table to copy from,
-- or an array storing multiple source tables.
-- @param multiple Specifies whether source contains
-- more than one table.
-- @return The target table with overwritten and 
-- appended values.
function utilities.assign(target, source, multiple)
  multiple = multiple or false
  if multiple == true then
    for count = 1, #source do
      target = utilities.assign(target, source[count])
    end
    return target
  else
    for k, v in pairs(source) do
      target[k] = v;
    end
  end
  return target;
end

--- Deep assigns the contents of a table to another.
-- Copy over the keys and values from source 
-- tables to a target. Will recurse through child
-- tables to copy over their keys/values as well.
-- @param target The table to be copied to.
-- @param source Either a table to copy from,
-- or an array storing multiple source tables.
-- @param multipleSource Specifies whether source
-- contains more than one table.
-- @param exclude Either a string or an array of
-- string containing keys to exclude from copying.
-- @param multipleExclude Specifies whether exclude
-- contains more than one string.
-- @return The target table with overwritten and 
-- appended values.
function utilities.deep_assign(target, source, multipleSource, exclude, multipleExclude)
    multipleSource = multipleSource or false
    exclude = exclude or nil
    multipleExclude = multipleExclude or false

    if multipleSource then
        for count = 1, #source do
            target = utilities.deep_assign(target, source[count], false, exclude, multipleExclude)
        end
        return target
    else
        for k, v in pairs(source) do
            local match = false
            if multipleExclude then
                for count = 1, #exclude do
                    if (k == exclude[count]) match = true
                end
            elseif exclude then
                if (k == exclude) match = true
            end
            if not match then
                if type(v) == "table" then
                    target[k] = utilities.deep_assign({}, v, false, exclude, multipleExclude)
                else
                    target[k] = v;
                end
            end
        end
    end
    return target;
end

--- The main wrapper object
-- of the library. 
-- Stores all curent instances
-- of tween objects and drives
-- them.
tween_machine = {
    instances = {}
}

--- Calls update() on all current
-- tween instances.
function tween_machine:update()
    for t in all(self.instances) do
        t:update()
    end
end

--- Adds a created tween instance to
-- the table. The passed in object only
-- needs to define the fields it needs 
-- to change, the rest will be defaulted
-- to the base tween object.
-- For example: 
-- tween_machine:add_tween({
-- func = linear,
-- v_start = 10,
-- v_end = 5
-- })
-- @param instance The tween object to add 
-- to the machine.
-- @return Returns the tween object.
function tween_machine:add_tween(instance)
    local this = 
    {
        func = nil,
        v_start = 0,
        v_end = 1,
        value = 0,
        start_time = 0,
        duration = 0,
        elapsed = 0,
        finished = false,
    
        --- Callbacks
        -- Will pass through value
        -- as argument.
        step_callbacks = {},
        -- Will pass through tween
        -- object as argument.
        finished_callbacks = {}
    }
    utilities.deep_assign(this, instance)
    setmetatable(this, __tween)
    add(self.instances, this)
    this:init()
    return this
end

--- The base table for all tween
-- objects.
-- @field func The easing function
-- to use for this tween.
-- @field v_start The starting value
-- for the tween.
-- @field v_end The end value of the 
-- tween.
-- @field value The value between
-- v_start and v_end representing
-- the current tween progress.
-- @field start_time The time at which 
-- the tween was started, set in init()
-- via the time() function.
-- @field duration The duration of time
-- the tween should last for.
-- @field elapsed The amount of time
-- elapsed since the tween was started.
-- @field finished A bool for whether 
-- or not the tween has finished 
-- running.
-- @field step_callbacks A table of 
-- registered callback functions.
-- Called in update() after a new 
-- value has been set.
-- Will call all registered functions
-- with value as the argument.
-- @field finished_callbacks A table
-- of registered callback functions.
-- Called at the end of update()
-- after the tween has been marked
-- as finished.
-- Will call all registered functions
-- with self as the argument.
__tween = {}
__tween.__index = __tween

--- Registers the passed in function
-- as a step callback, to be called
-- in update() after a new value has
-- been set.
-- @param func The function to be 
-- called every step.
function __tween:register_step_callback(func)
    add(self.step_callbacks, func)
end

--- Registers the passed in function
-- as a finished callback, to be 
-- called at the end of update()
-- after the tween has been marked
-- as finished.
-- @param func The function to be 
-- called when finished.
function __tween:register_finished_callback(func)
    add(self.finished_callbacks, func)
end

--- Sets the tween's necessary
-- fields prior to being 
-- ran.
-- Called automatically when
-- added to the wrapper object
-- or when restarted.
function __tween:init()
    self.start_time = time()
    self.value = self.v_start
end

--- Restarts the tween's 
-- necessary fields in order to be
-- ran again.
function __tween:restart()
    self:init()
    self.elapsed = 0
    self.finished = false
end

--- Updates the tween object.
-- Gets the current value for the 
-- tween from the set function and
-- will pass it through all the 
-- registered step callbacks.
-- Will set the tween as finished
-- when the elapsed time passes
-- the duration and will pass 
-- the tween object to all 
-- registered finished callback
-- functions.
-- @return Will return early if
-- the tween is finished or no
-- easing function has been set.
function __tween:update()
    if (self.finished or self.func == nil) return

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

--- Removes the tween from the 
-- wrapper object.
function __tween:remove()
    del(tween_machine.instances, self)
end