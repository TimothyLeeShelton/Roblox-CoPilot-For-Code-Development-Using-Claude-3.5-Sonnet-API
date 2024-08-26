--Fun statement to test a single script being changed at a time: Add a print statement to the onboardingtutorialcontrol script in serverscriptservice at the start of the "updateDataStore" function. 
--Fun statement to test multiple scripts being changed at a time: Add a print statement to the onboardingtutorialcontrol script in serverscriptservice at the start of the "updateDataStore" function. For a second change, adjust the MAX_PAIRS_PER_KEY value in TimePlayedDataStore to 19999.





--Going to add "I'm Feeling lucky" wildcards where we essentially create pickable cards of what the user could build. 
--Going to add some kind of loading screen indicator while we wait for prompts to complete so users know to chill. 

-- Required services
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")
local UserInputService = game:GetService("UserInputService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Variables for API selection and key
local selectedAPIProvider = nil
local apiKey = nil

local existingScripts = {} 
local scriptBackups = {}
local undoButton

-- Create DockWidgetPluginGui
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	400,
	300,
	300,
	200
)

-- Create the main plugin GUI
local pluginGui = plugin:CreateDockWidgetPluginGui("CodeUpdaterGUI", widgetInfo)
pluginGui.Title = "Code Updater"

-- Create main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, 0, 1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(247, 250, 252)
Frame.BorderSizePixel = 0
Frame.Parent = pluginGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

-- Create API Provider Dropdown
local APIProviderDropdown = Instance.new("TextButton")
APIProviderDropdown.Size = UDim2.new(0.3, 0, 0.1, 0)
APIProviderDropdown.Position = UDim2.new(0.68, 0, 0.02, 0)
APIProviderDropdown.Text = "API Provider"
APIProviderDropdown.Font = Enum.Font.SourceSansBold
APIProviderDropdown.TextSize = 14
APIProviderDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
APIProviderDropdown.BackgroundColor3 = Color3.fromRGB(99, 91, 255)
APIProviderDropdown.Parent = Frame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 4)
DropdownCorner.Parent = APIProviderDropdown

-- Create Dropdown Menu
local DropdownMenu = Instance.new("Frame")
DropdownMenu.Size = UDim2.new(0.3, 0, 0.3, 0)
DropdownMenu.Position = UDim2.new(0.68, 0, 0.12, 0)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DropdownMenu.Visible = false
DropdownMenu.ZIndex = 10
DropdownMenu.Parent = Frame

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 4)
MenuCorner.Parent = DropdownMenu

-- Create API Key Input
local APIKeyInput = Instance.new("TextBox")
APIKeyInput.Size = UDim2.new(0.8, 0, 0.1, 0)
APIKeyInput.Position = UDim2.new(0.1, 0, 0.2, 0)
APIKeyInput.ClearTextOnFocus = false
APIKeyInput.Font = Enum.Font.SourceSans
APIKeyInput.TextSize = 12
APIKeyInput.TextColor3 = Color3.fromRGB(0, 0, 0)
APIKeyInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
APIKeyInput.Visible = false
APIKeyInput.Parent = Frame

local APIKeyCorner = Instance.new("UICorner")
APIKeyCorner.CornerRadius = UDim.new(0, 4)
APIKeyCorner.Parent = APIKeyInput

-- Create Use API Key Button
local UseAPIKeyButton = Instance.new("TextButton")
UseAPIKeyButton.Size = UDim2.new(0.3, 0, 0.1, 0)
UseAPIKeyButton.Position = UDim2.new(0.35, 0, 0.32, 0)
UseAPIKeyButton.Text = "Use This API Key"
UseAPIKeyButton.Font = Enum.Font.SourceSansBold
UseAPIKeyButton.TextSize = 14
UseAPIKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UseAPIKeyButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)
UseAPIKeyButton.Visible = false
UseAPIKeyButton.Parent = Frame

local UseKeyCorner = Instance.new("UICorner")
UseKeyCorner.CornerRadius = UDim.new(0, 4)
UseKeyCorner.Parent = UseAPIKeyButton

-- Create ScrollingFrame for user input
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
ScrollingFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollingEnabled = true
ScrollingFrame.Parent = Frame
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
ScrollingFrame.Visible = false

-- Create TextBox for user input
local UserRequestInput = Instance.new("TextBox")
UserRequestInput.Size = UDim2.new(1, 0, 1, 0)
UserRequestInput.Position = UDim2.new(0, 0, 0, 0)
UserRequestInput.Text = "Enter your code update request here..."
UserRequestInput.TextColor3 = Color3.fromRGB(66, 84, 102)
UserRequestInput.BackgroundColor3 = Color3.fromRGB(241, 244, 227)
UserRequestInput.Font = Enum.Font.SourceSansSemibold
UserRequestInput.MultiLine = true
UserRequestInput.TextWrapped = true
UserRequestInput.TextSize = 14
UserRequestInput.ClearTextOnFocus = false
UserRequestInput.Parent = ScrollingFrame

local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 4)
TextBoxCorner.Parent = UserRequestInput

local TextBoxPadding = Instance.new("UIPadding")
TextBoxPadding.PaddingLeft = UDim.new(0, 8)
TextBoxPadding.PaddingRight = UDim.new(0, 8)
TextBoxPadding.PaddingTop = UDim.new(0, 8)
TextBoxPadding.PaddingBottom = UDim.new(0, 8)
TextBoxPadding.Parent = UserRequestInput

local TextSizeConstraint = Instance.new("UITextSizeConstraint")
TextSizeConstraint.MaxTextSize = 14
TextSizeConstraint.MinTextSize = 10
TextSizeConstraint.Parent = UserRequestInput

-- Create Send Button
local SendButton = Instance.new("TextButton")
SendButton.Size = UDim2.new(0.3, 0, 0.15, 0)
SendButton.Position = UDim2.new(0.35, 0, 0.7, 0)
SendButton.Text = "Update Code"
SendButton.Font = Enum.Font.SourceSansBold
SendButton.TextSize = 16
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SendButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)
SendButton.Parent = Frame
SendButton.Visible = false

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 4)
ButtonCorner.Parent = SendButton

-- Create Response Text area
local ResponseText = Instance.new("TextLabel")
ResponseText.Size = UDim2.new(0.9, 0, 0.1, 0)
ResponseText.Position = UDim2.new(0.05, 0, 0.89, 0)
ResponseText.BackgroundTransparency = 1
ResponseText.Text = ""
ResponseText.TextColor3 = Color3.fromRGB(66, 84, 102)
ResponseText.Font = Enum.Font.SourceSansSemibold
ResponseText.TextSize = 14
ResponseText.TextWrapped = true
ResponseText.TextXAlignment = Enum.TextXAlignment.Center
ResponseText.Parent = Frame

-- Create Undo Button
undoButton = Instance.new("TextButton")
undoButton.Size = UDim2.new(0.3, 0, 0.1, 0)
undoButton.Position = UDim2.new(0.68, 0, 0.88, 0)
undoButton.Text = "Undo Changes"
undoButton.Font = Enum.Font.SourceSansBold
undoButton.TextSize = 16
undoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
undoButton.BackgroundColor3 = Color3.fromRGB(234, 76, 137)
undoButton.Parent = Frame
undoButton.Visible = false

local UndoButtonCorner = Instance.new("UICorner")
UndoButtonCorner.CornerRadius = UDim.new(0, 4)
UndoButtonCorner.Parent = undoButton

-- Function to update ScrollingFrame size based on text content
local function updateScrollingFrame()
	local textBounds = UserRequestInput.TextBounds
	local frameHeight = ScrollingFrame.AbsoluteSize.Y
	UserRequestInput.Size = UDim2.new(1, -12, 0, math.max(textBounds.Y, frameHeight))
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(textBounds.Y, frameHeight))
end

-- Connect the update function to relevant events
UserRequestInput:GetPropertyChangedSignal("Text"):Connect(updateScrollingFrame)
UserRequestInput:GetPropertyChangedSignal("TextBounds"):Connect(updateScrollingFrame)

-- Double-click to clear text functionality
local lastClickTime = 0
UserRequestInput.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local currentTime = tick()
		if currentTime - lastClickTime < 1 then
			UserRequestInput.Text = ""
		end
		lastClickTime = currentTime
	end
end)

-- Create Dropdown Options
local options = {"OpenAI", "Anthropic", "Google"}
for i, option in ipairs(options) do
	local OptionButton = Instance.new("TextButton")
	OptionButton.Size = UDim2.new(1, 0, 0.33, 0)
	OptionButton.Position = UDim2.new(0, 0, (i-1) * 0.33, 0)
	OptionButton.Text = option
	OptionButton.Font = Enum.Font.SourceSans
	OptionButton.TextSize = 14
	OptionButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	OptionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	OptionButton.Parent = DropdownMenu
	OptionButton.ZIndex = 11

	OptionButton.MouseButton1Click:Connect(function()
		selectedAPIProvider = option
		APIProviderDropdown.Text = option
		DropdownMenu.Visible = false
		APIKeyInput.Visible = true
		APIKeyInput.Text = apiKey or "Enter API Key..."
		UseAPIKeyButton.Visible = true
		ScrollingFrame.Visible = false
		SendButton.Visible = false
	end)
end

-- Toggle Dropdown Menu
APIProviderDropdown.MouseButton1Click:Connect(function()
	DropdownMenu.Visible = not DropdownMenu.Visible
	if DropdownMenu.Visible then
		DropdownMenu.ZIndex = 10
		ScrollingFrame.Visible = true
		SendButton.Visible = true
	end
end)

-- Use API Key Button Click Handler
UseAPIKeyButton.MouseButton1Click:Connect(function()
	apiKey = APIKeyInput.Text
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
	ScrollingFrame.Visible = true
	SendButton.Visible = true
end)

-- Function to create an undo point
local function createUndoPoint(description)
	ChangeHistoryService:SetWaypoint(description)
end

-- Function to create the API prompt
local function createAPIPrompt(codebase, userRequest)
	return [[
		Please analyze the following codebase and make the requested changes. You need to determine the number of actions required to implement the change, the type of each action, and each action should be it's own array with the appropriate values in the array of changes. 
		
		There are 3 types of action: 
		1) Modify Existing Code: Identify the service, script, and code chunk relevant to the action required by the user's prompt, respond with the original code snippet as the "previousCode" value, the "newCode" value which is the updated version of the code snippet, and the "explanation" which is a text explanation of the changes made and the part of the user's request that prompted those changes. 
		2) Add new code without modifying existing code snippets. Identify the service and script relevant most relevant to the action required by the user's prompt, only if there is an appropriate service and script already existing do we proceed with this type of action, otherwise we do a "NewScript" action. If we have identified a service and script properly relevant, we respond with this "AddOnly" action and it's "newCode" value which is the new code snippet, and the "explanation" which is a text explanation of the changes made and the part of the user's request that prompted those changes. 
		3) Create a new script and populate it with the code required to complete the requirements. This is the action type that occurs when we cannot identify an appropriately relevant pre-existing service and script, or service, script, and code chunk to warrant a "ModifyExisting" or a "AddOnly" action. In this scenario we create a new script and populate it with the code required to complete the requirement. 
		
		Respond with a JSON structure containing the appropriate actions to complete the requirements that were requested.
		
		User Request: ]] .. userRequest .. [[  
		
		Codebase:]] .. codebase .. [[ 
		
		Remember that you need to consider the dependencies your newCode will need, and if the previousCode doesn't have them, they need to be in your newCode at the appropriate place in the script: 
			- If it's a ModifyExisting action type or AddOnly action type and your newCode response has dependencies it relies on, if the if your previouscode doesn't have the required dependencies you need to add in the necessary dependencies to the appropriate location of the newcode. An example is if your newCode had "ReplicatedStorage.RoundStartBindableEvent.Event:Connect(onBindableEvent)" and the previousCode didn't already have "local ReplicatedStorage = game:getservice("ReplicatedStorage")" you would need to add that dependency declaration to the top of the script in your newcode, etc...
			- If it's a NewScript action type, then obviously the required dependencies won't be there yet so you need to include them.
		
		Keep in mind that Roblox development requires that dependencies are chronologically defined in the order that they are used, you can't use a dependency if it wasn't defined on a previous line.
		
		Regarding your response in json structure please note: 
			1) We are using camelCase for our capitalization structure of the responses keys
			2) Please provide your response as a raw JSON object without any markdown formatting or code block indicators. Do not use triple backticks (```) or any other formatting around the JSON. The response should start with an opening curly brace ({) and end with a closing curly brace (}).
			3) Provide your response in the following JSON format, just respond with this json structure, no extra fluff, your response is going directly into a json decoder so any fluff will break it:
		{
		    "changes": [
		        {
                    "actionType": "ModifyExisting",
		            "previousCode": "Exact snippet of code to be replaced",
		            "newCode": "Updated version of the code snippet",
                    "scriptName": "Name of the script where the action is being implemented",
                    "serviceName": "Name of the service where the action is being implemented",
                    "lineNumber": null (modifications occur where the existing relevant code chunks are being changed, with the previous code commented above the new code),
		            "explanation": "Brief explanation of the changes made"
		        },
                 {
                    "actionType": "AddOnly",
		            "previousCode": null,
		            "newCode": "The new code snippet",
                    "scriptName": "Name of the script where the action is being implemented",
                    "serviceName": "Name of the service where the action is being implemented",
                    "lineNumber": null (modifications occur where the existing relevant code chunks are being changed, with the previous code commented above the new code),
		            "explanation": "Brief explanation of the changes made"
		        },
                {
                    "actionType": "NewScript
                    "actionType": "NewScript"
		            "previousCode": null,
		            "newCode": "The new code snippet",
                    "scriptName": "Name of the script where the action is being implemented",
                    "serviceName": "Name of the service where the action is being implemented",
                    "lineNumber": null (modifications occur where the existing relevant code chunks are being changed, with the previous code commented above the new code),
		            "explanation": "Brief explanation of the changes made"
		        }
		    ]
		}
		Only include the JSON in your response, without any additional text or formatting.
	]]
end

local function cleanAPIResponse(response)
	-- Remove any leading or trailing whitespace
	response = response:match("^%s*(.-)%s*$")

	-- Remove triple backticks and the word "json" if present
	response = response:gsub("^```json%s*", ""):gsub("^```%s*", ""):gsub("%s*```$", "")

	-- Ensure the response starts with { and ends with }
	if not response:match("^%s*{") or not response:match("}%s*$") then
		error("Invalid JSON response")
	end

	return response
end

-- Function to send request to the selected API
local function sendToAPI(scriptData, userRequest)
	local prompt = createAPIPrompt(HttpService:JSONEncode(scriptData), userRequest)
	local url, headers, body

	print("Going to send to api")

	if selectedAPIProvider == "OpenAI" then
		url = "https://api.openai.com/v1/chat/completions"
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. apiKey
		}
		body = HttpService:JSONEncode({
			model = "gpt-4",
			messages = {{role = "user", content = prompt}},
			max_tokens = 4096
		})
	elseif selectedAPIProvider == "Anthropic" then
		url = "https://api.anthropic.com/v1/messages"
		headers = {
			["Content-Type"] = "application/json",
			["x-api-key"] = apiKey,
			["anthropic-version"] = "2023-06-01"
		}
		body = HttpService:JSONEncode({
			model = "claude-3-5-sonnet-20240620",
			messages = {{role = "user", content = prompt}},
			max_tokens = 4096
		})
	elseif selectedAPIProvider == "Google" then
		print("Google is provider, sending a prompt to google.")
		url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
		headers = {
			["Content-Type"] = "application/json",
		}
		body = HttpService:JSONEncode({
			contents = {{
				parts = {{text = prompt}}
			}},
			generationConfig = {
				temperature = 0.7,
				topK = 40,
				topP = 0.95,
				maxOutputTokens = 4096,
			},
		})
		url = url .. "?key=" .. apiKey
		print("URL we're sending to google is: ", url)
	else
		return "Error: Invalid API provider selected"
	end

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = headers,
			Body = body
		})
	end)

	if success then
		if response.Success then
			local responseData = HttpService:JSONDecode(response.Body)
			if selectedAPIProvider == "OpenAI" then
				return cleanAPIResponse(responseData.choices[1].message.content)
			elseif selectedAPIProvider == "Anthropic" then
				return cleanAPIResponse(responseData.content[1].text)
			elseif selectedAPIProvider == "Google" then
				return cleanAPIResponse(responseData.candidates[1].content.parts[1].text)
			end
		else
			print(response)
			return "Error: API request failed with status "
		end
	else
		return "Error: " .. tostring(response)
	end
end





-- Function to apply code changes suggested by API
local function applyCodeChanges(apiResponse)
	print("Applying code changes function started")
	local cleanedResponse = cleanAPIResponse(apiResponse)
	local changes = HttpService:JSONDecode(cleanedResponse).changes
	print("Content of changes to apply in applyCodeChanges function are: ", changes)

	for _, change in ipairs(changes) do
		if change.actionType == "ModifyExisting" then
			local previousCode = change.previousCode
			local newCode = change.newCode
			local scriptName = change.scriptName
			local serviceName = change.serviceName

			print("Previous code is: ", previousCode)
			print("New Code is: ", newCode)

			local service = game:GetService(serviceName)
			if service then
				local script = service:FindFirstChild(scriptName, true)
				if script and (script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript")) then
					local source = script.Source
					local startIndex, endIndex = string.find(source, previousCode, 1, true)

					if startIndex then
						print("Matching code found in Script: ", script.Name)
						local commentedCode = string.gsub(previousCode, "([^\r\n]+)", "--[[ %1 ]]")
						local updatedSource = string.sub(source, 1, startIndex - 1) .. commentedCode .. "\n" .. newCode .. "\n" .. string.sub(source, endIndex + 1)
						script.Source = updatedSource

						ScriptEditorService:UpdateSourceAsync(script, function()
							return updatedSource
						end)

						plugin:OpenScript(script, startIndex)
						print("Updated script: " .. script.Name .. " in Service: " .. service.Name .. " \n \n \n \n With updated source of:" .. updatedSource)
					end
				end
			end
		elseif change.actionType == "AddOnly" then
			local newCode = change.newCode
			local scriptName = change.scriptName
			local serviceName = change.serviceName

			local service = game:GetService(serviceName)
			if service then
				local script = service:FindFirstChild(scriptName, true)
				if script and (script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript")) then
					local updatedSource = script.Source .. "\n\n" .. newCode
					script.Source = updatedSource

					ScriptEditorService:UpdateSourceAsync(script, function()
						return updatedSource
					end)

					plugin:OpenScript(script, #script.Source)
					print("Added code to script: " .. script.Name .. " in Service: " .. service.Name)
				end
			end
		elseif change.actionType == "NewScript" then
			local newCode = change.newCode
			local scriptName = change.scriptName
			local serviceName = change.serviceName

			print("We know its a new script request, newcode is: ", newCode," scriptName is: ", scriptName, " Servicename is: ",serviceName)

			local service = game:GetService(serviceName)
			if service then
				print("we found the service to place the new script in which is: ", service)
				local newScript = Instance.new("Script")
				newScript.Name = scriptName
				newScript.Source = newCode
				newScript.Parent = service

				scriptBackups[newScript] = ""  --Empty string indicates it's a new script. 

				plugin:OpenScript(newScript, 1)
				print("Created new script: " .. scriptName .. " in Service: " .. serviceName)
			end
		end
	end
end

-- Function to serialize scripts from a specific service
local function serializeScriptsFromService(service)
	local scriptsData = {}

	for _, script in ipairs(service:GetDescendants()) do
		if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
			table.insert(scriptsData, {
				Name = script.Name,
				ClassName = script.ClassName,
				ParentName = script.Parent and script.Parent.Name or "None",
				Source = script.Source
			})
		end
	end

	print("Serialized " .. #scriptsData .. " scripts from " .. service.Name)

	return scriptsData
end


-- Modify the serializeAllScripts function
local function serializeAllScripts()
	local allScriptsData = {}
	scriptBackups = {}
	existingScripts = {}  -- Reset the existing scripts list

	local servicesToCheck = {game.ServerScriptService, game.ReplicatedStorage, game.StarterGui}

	for _, serviceBeingChecked in pairs(servicesToCheck) do
		for _, script in ipairs(serviceBeingChecked:GetDescendants()) do
			if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
				local scriptData = {
					Name = script.Name,
					ClassName = script.ClassName,
					ParentName = script.Parent and script.Parent.Name or "None",
					Source = script.Source
				}

				table.insert(allScriptsData, scriptData)
				scriptBackups[script] = script.Source
				table.insert(existingScripts, script)  -- Add this line to keep track of existing scripts
			end
		end
	end

	print("Serialized and backed up " .. #allScriptsData .. " scripts from " .. #servicesToCheck .. " services")

	return allScriptsData
end

local function revertChanges()
	for script, originalSource in pairs(scriptBackups) do
		if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
			if table.find(existingScripts, script) then
				-- This is an existing script, revert its contents
				script.Source = originalSource

				ScriptEditorService:UpdateSourceAsync(script, function()
					return originalSource
				end)
			else
				-- This is a new script, remove it
				script:Destroy()
			end
		end
	end

	-- Remove any new scripts that were created
	local servicesToCheck = {game.ServerScriptService, game.ReplicatedStorage, game.StarterGui}
	for _, service in ipairs(servicesToCheck) do
		for _, script in ipairs(service:GetDescendants()) do
			if (script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript")) and not table.find(existingScripts, script) then
				script:Destroy()
			end
		end
	end

	ResponseText.Text = "Changes reverted"
	ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)
	undoButton.Visible = false
end

-- Connect the revertChanges function to the undo button's click event
undoButton.MouseButton1Click:Connect(revertChanges)

-- Function to update code based on user request
local function updateCode()
	local userRequest = UserRequestInput.Text
	local serializedScripts = serializeAllScripts()
	local apiResponse = sendToAPI(serializedScripts, userRequest)

	if apiResponse:sub(1, 5) == "Error" then
		ResponseText.Text = apiResponse
		ResponseText.TextColor3 = Color3.fromRGB(234, 76, 137)
	else
		print("Going to apply changes: ", apiResponse)
		applyCodeChanges(apiResponse)
		ResponseText.Text = "Success"
		ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)
		undoButton.Visible = true
	end

	print("Completed updateCode function")
end

-- Connect the updateCode function to the send button's click event
SendButton.MouseButton1Click:Connect(updateCode)

-- Create a toolbar button to toggle the widget
local toolbar = plugin:CreateToolbar("Code Updater")
local toggleButton = toolbar:CreateButton("ToggleUpdater", "Toggle Code Updater", "")

-- Toggle button handler
toggleButton.Click:Connect(function()
	pluginGui.Enabled = not pluginGui.Enabled
end)

-- Initialize the plugin
local function init()
	ScrollingFrame.Visible = false
	SendButton.Visible = false
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
end

-- Call the initialization function
init()
