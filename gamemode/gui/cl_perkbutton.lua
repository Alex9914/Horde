local PANEL = {}

surface.CreateFont("Horde_PerkButton_Name", { font = "arial bold", size = 20, bold = true })
surface.CreateFont("Horde_PerkButton_Text", { font = "arial bold", size = 16, bold = true})

local function getweaponname(class)
    if language.GetPhrase(class) ~= class then return language.GetPhrase(class) end
    if weapons.Get(class) then return weapons.Get(class).PrintName end
    return class
end

function PANEL:Init()
    local w, h = ScrW() * 0.1, ScrH() * 0.075
    self:SetSize(w, h)
    self:SetText("")

    self.icon = vgui.Create("DImage", self)
    self.icon:SetSize(h, h)
    self.icon:Dock(LEFT)

    self.title = vgui.Create("DLabel", self)
    self.title:SetSize(w, 16)
    self.title:Dock(TOP)
    self.title:DockMargin(5, 5, 0, 0)
    self.title:SetFont("Horde_PerkButton_Name")
    self.title:SetText("Perk Name")
    self.title:SetColor(color_white)

    self.desc = vgui.Create("DLabel", self)
    self.desc:Dock(FILL)
    self.desc:DockMargin(5, 3, 5, 0)
    self.desc:SetText("Perk Description")
    self.desc:SetColor(color_white)
end

function PANEL:DoClick()
    surface.PlaySound("UI/buttonclick.wav")
    if not self.info then return end
    LocalPlayer().Horde_PerkChoices = LocalPlayer().Horde_PerkChoices or {}
    LocalPlayer().Horde_PerkChoices[self.info.class] = LocalPlayer().Horde_PerkChoices[self.info.class] or {}
    LocalPlayer().Horde_PerkChoices[self.info.class][self.info.perk_level] = self.info.choice
    file.Write("horde/perk_choices.txt", util.TableToJSON(LocalPlayer().Horde_PerkChoices))
    net.Start("Horde_PerkChoice")
        net.WriteString(self.info.class)
        net.WriteUInt(self.info.perk_level, 4)
        net.WriteUInt(self.info.choice, 4)
    net.SendToServer()
end

function PANEL:OnCursorEntered()
    if self.info and self.info.active then
        self.bg_color = Color(100, 150, 100)
    else
        self.bg_color = Color(100, 100, 100)
    end
end

function PANEL:OnCursorExited()
    if self.info and self.info.active then
        self.bg_color = Color(50, 80, 50)
    else
        self.bg_color = Color(50, 50, 50)
    end
    surface.PlaySound("UI/buttonrollover.wav")
end

function PANEL:SetData(classname, perk_level, choice)
    local perk_choice = HORDE.classes[classname].perks[perk_level].choices[choice]
    if not perk_choice then error("Could not find choice! class: " .. classname .. ", level: " .. perk_level .. ", choice: " .. choice) return end
    self.info = {class = classname, perk_level = perk_level, choice = choice}

    local perk = HORDE.perks[perk_choice]
    if not perk then error("Could not find perk '" .. perk .. "'!") return end

    local icon = perk.Icon
    if icon then
        self.icon:SetMaterial(Material(icon, "mips smooth"))
    else
        self.icon:SetMaterial(Material("materials/" .. classname .. ".png", "mips smooth"))
    end

    LocalPlayer().Horde_PerkChoices = LocalPlayer().Horde_PerkChoices or {}
    LocalPlayer().Horde_PerkChoices[classname] = LocalPlayer().Horde_PerkChoices[classname] or {}
    local tbl_choices = LocalPlayer().Horde_PerkChoices[classname]

    self.info.active = (tbl_choices[perk_level] or 1) == choice
    
    self.title:SetText(perk.PrintName or "Unnamed Perk")
    self.desctext = ""
    local text = perk.Description
    self.desctext = self.desctext .. text .. "\n"

    self.desc:SetText(self.desctext)
    self.desc:SetFont("Horde_PerkButton_Text")

    if self.info and self.info.active then
        self.bg_color = Color(220, 20, 60, 150)
    else
        self.bg_color = Color(50, 50, 50)
    end
end

function PANEL:Think()
    if not self.info then return end
    self.info.active = (LocalPlayer().Horde_PerkChoices[self.info.class][self.info.perk_level] or 1) == self.info.choice
    self.bg_color = self.info.active and Color(220, 20, 60, 150) or Color(50, 50, 50)
end

function PANEL:Paint(w,h)
    -- Entire Panel
    draw.RoundedBox(10, 0, 0, w, h, self.bg_color)
end

vgui.Register("HordePerkButton", PANEL, "DButton")