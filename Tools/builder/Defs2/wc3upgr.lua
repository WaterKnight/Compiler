local t = {}

t.defFunc = function(t)
	addToEnv(t)
end

t.createFunc = function(t)
	addToEnv(t)

	local widget = createWidget('upgrade', getVal('raw', 1), nil, getVal('profileIdent', 1), path)

	widget:doSpecials(getVal('specialsTrue'), getVal('specials'))
end

t.jassType = nil
t.jassTypeDummy = 'integer'

t.jassIniter = nil

t.jassFunc = function(t)
	addToEnv(t)
end

t.jassFuncDummy = function(t, jStream)
	addToEnv(t)

	addVar(getVal('jassVar', 1)..'Id', 'integer', getVal('jassVarIndex', 1))
end

return t