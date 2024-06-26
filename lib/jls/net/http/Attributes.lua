--- A class that holds attributes as key-value pairs.
-- The attributes are stored in the table field "attributes".
-- @module jls.net.http.Attributes
-- @pragma nostrip

--- A class that holds attributes.
-- @type Attributes
return require('jls.lang.class').create(function(attributes)

  --- Creates a new Attributes.
  -- @function Attributes:new
  function attributes:initialize()
    self.attributes = {}
  end

  --- Sets the specified value for the specified name.
  -- @tparam string name the attribute name
  -- @param value the attribute value
  function attributes:setAttribute(name, value)
    self.attributes[name] = value
    return self
  end

  --- Returns the value for the specified name.
  -- @tparam string name the attribute name
  -- @return the attribute value
  function attributes:getAttribute(name)
    return self.attributes[name]
  end

  --- Removes the value for the specified name.
  -- @tparam string name the attribute name
  -- @return the attribute value
  function attributes:removeAttribute(name)
    self.attributes[name] = nil
    return self
  end

  function attributes:getAttributes()
    return self.attributes
  end

  function attributes:setAttributes(attrs)
    for name, value in pairs(attrs) do
      self:setAttribute(name, value)
    end
    return self
  end

  function attributes:cleanAttributes()
    self.attributes = {}
  end

end)