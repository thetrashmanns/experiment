local ui = {}

function ui:init()
    self.objs = {}
    self.objs.info_form = loveframes.Create("form")
    self.objs.info_form:SetWidth(1300)
    self.objs.info_form:SetHeight(700)
    self.objs.att_ver = loveframes.Create("multichoice", self.objs.info_form)
    self.objs.att_ver:SetPos(0, 0)
end

return ui