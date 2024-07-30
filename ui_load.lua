local ui = {}

function ui:init()
    self.objs = {}
    self.objs.info_form = loveframes.Create("form")
    self.objs.info_form:SetWidth(1366)
    self.objs.info_form:SetHeight(768)
    self.objs.att_ver = loveframes.Create("multichoice", self.objs.info_form)
    self.objs.att_ver:SetPos(0, 7)
    for i = 11, 17 do
        self.objs.att_ver:AddChoice("ATT" .. tostring(i))
    end
    self.objs.att_codes = loveframes.Create("textinput")
    self.objs.att_codes:SetMultiline(true)
    self.objs.att_codes:SetText("Input ATT Codes here.")
    
end

return ui