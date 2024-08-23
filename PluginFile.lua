--Fun statement to test a single script being changed at a time: Add a print statement to the onboardingtutorialcontrol script in serverscriptservice at the start of the "updateDataStore" function. 
--Fun statement to test multiple scripts being changed at a time: Add a print statement to the onboardingtutorialcontrol script in serverscriptservice at the start of the "updateDataStore" function. For a second change, adjust the MAX_PAIRS_PER_KEY value in TimePlayedDataStore to 19999.

-- Required services
local HttpService = game:GetService("HttpService")  -- For making HTTP requests and JSON encoding/decoding
local ServerStorage = game:GetService("ServerStorage")  -- For accessing server-side storage
local ScriptEditorService = game:GetService("ScriptEditorService")  -- For updating script sources
local UserInputService = game:GetService("UserInputService")  -- For handling user input
local ChangeHistoryService = game:GetService("ChangeHistoryService")  -- For managing undo/redo functionality

-- Variables for API selection and key
local selectedAPIProvider = nil  -- Stores the selected API provider
local apiKey = nil  -- Stores the API key

local scriptBackups = {}  -- Table to store backups of original scripts
local undoButton  -- Variable to hold the undo button GUI element

-- Create DockWidgetPluginGui
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Initial dock state
	false,  -- Initially enabled
	false,  -- Override enabled
	400,  -- Default width
	300,  -- Default height
	300,  -- Minimum width
	200   -- Minimum height
)

-- Create the main plugin GUI
local pluginGui = plugin:CreateDockWidgetPluginGui("CodeUpdaterGUI", widgetInfo)
pluginGui.Title = "Code Updater"

-- Create main Frame
local Frame = Instance.new("Frame")  -- Create the main frame for the GUI
Frame.Size = UDim2.new(1, 0, 1, 0)  -- Set frame size to fill the entire plugin window
Frame.BackgroundColor3 = Color3.fromRGB(247, 250, 252)  -- Set background color
Frame.BorderSizePixel = 0  -- Remove border
Frame.Parent = pluginGui  -- Set parent to the plugin GUI

local FrameCorner = Instance.new("UICorner")  -- Create rounded corners for the frame
FrameCorner.CornerRadius = UDim.new(0, 8)  -- Set corner radius
FrameCorner.Parent = Frame  -- Set parent to the main frame

-- Create API Provider Dropdown
local APIProviderDropdown = Instance.new("TextButton")  -- Create dropdown button for API provider selection
APIProviderDropdown.Size = UDim2.new(0.3, 0, 0.1, 0)  -- Set button size
APIProviderDropdown.Position = UDim2.new(0.68, 0, 0.02, 0)  -- Set button position
APIProviderDropdown.Text = "API Provider"  -- Set button text
APIProviderDropdown.Font = Enum.Font.SourceSansBold  -- Set font
APIProviderDropdown.TextSize = 14  -- Set text size
APIProviderDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Set text color
APIProviderDropdown.BackgroundColor3 = Color3.fromRGB(99, 91, 255)  -- Set background color
APIProviderDropdown.Parent = Frame  -- Set parent to the main frame

local DropdownCorner = Instance.new("UICorner")  -- Create rounded corners for the dropdown button
DropdownCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
DropdownCorner.Parent = APIProviderDropdown  -- Set parent to the dropdown button

-- Create Dropdown Menu
local DropdownMenu = Instance.new("Frame")  -- Create frame for dropdown menu
DropdownMenu.Size = UDim2.new(0.3, 0, 0.3, 0)  -- Set menu size
DropdownMenu.Position = UDim2.new(0.68, 0, 0.12, 0)  -- Set menu position
DropdownMenu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- Set background color
DropdownMenu.Visible = false  -- Initially hidden
DropdownMenu.ZIndex = 10  -- Ensure it appears on top
DropdownMenu.Parent = Frame  -- Set parent to the main frame

local MenuCorner = Instance.new("UICorner")  -- Create rounded corners for the dropdown menu
MenuCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
MenuCorner.Parent = DropdownMenu  -- Set parent to the dropdown menu

-- Create API Key Input
local APIKeyInput = Instance.new("TextBox")  -- Create textbox for API key input
APIKeyInput.Size = UDim2.new(0.8, 0, 0.1, 0)  -- Set textbox size
APIKeyInput.Position = UDim2.new(0.1, 0, 0.2, 0)  -- Set textbox position
APIKeyInput.ClearTextOnFocus = false  -- Don't clear text when focused
APIKeyInput.Font = Enum.Font.SourceSans  -- Set font
APIKeyInput.TextSize = 12  -- Set text size
APIKeyInput.TextColor3 = Color3.fromRGB(0, 0, 0)  -- Set text color
APIKeyInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- Set background color
APIKeyInput.Visible = false  -- Initially hidden
APIKeyInput.Parent = Frame  -- Set parent to the main frame

local APIKeyCorner = Instance.new("UICorner")  -- Create rounded corners for the API key input
APIKeyCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
APIKeyCorner.Parent = APIKeyInput  -- Set parent to the API key input

-- Create Use API Key Button
local UseAPIKeyButton = Instance.new("TextButton")  -- Create button to confirm API key
UseAPIKeyButton.Size = UDim2.new(0.3, 0, 0.1, 0)  -- Set button size
UseAPIKeyButton.Position = UDim2.new(0.35, 0, 0.32, 0)  -- Set button position
UseAPIKeyButton.Text = "Use This API Key"  -- Set button text
UseAPIKeyButton.Font = Enum.Font.SourceSansBold  -- Set font
UseAPIKeyButton.TextSize = 14  -- Set text size
UseAPIKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Set text color
UseAPIKeyButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)  -- Set background color
UseAPIKeyButton.Visible = false  -- Initially hidden
UseAPIKeyButton.Parent = Frame  -- Set parent to the main frame

local UseKeyCorner = Instance.new("UICorner")  -- Create rounded corners for the Use API Key button
UseKeyCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
UseKeyCorner.Parent = UseAPIKeyButton  -- Set parent to the Use API Key button

-- Create ScrollingFrame for user input
local ScrollingFrame = Instance.new("ScrollingFrame")  -- Create scrolling frame for user input
ScrollingFrame.Size = UDim2.new(0.9, 0, 0.5, 0)  -- Set frame size
ScrollingFrame.Position = UDim2.new(0.05, 0, 0.15, 0)  -- Set frame position
ScrollingFrame.BackgroundTransparency = 1  -- Make background transparent
ScrollingFrame.ScrollBarThickness = 6  -- Set scrollbar thickness
ScrollingFrame.ScrollingEnabled = true  -- Enable scrolling
ScrollingFrame.Parent = Frame  -- Set parent to the main frame
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y  -- Allow vertical scrolling
ScrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right  -- Position scrollbar on the right
ScrollingFrame.Visible = false  -- Initially hidden

-- Create TextBox for user input
local UserRequestInput = Instance.new("TextBox")  -- Create textbox for user input
UserRequestInput.Size = UDim2.new(1, 0, 1, 0)  -- Set textbox size to fill the scrolling frame
UserRequestInput.Position = UDim2.new(0, 0, 0, 0)  -- Set textbox position
UserRequestInput.Text = "Enter your code update request here..."  -- Set default text
UserRequestInput.TextColor3 = Color3.fromRGB(66, 84, 102)  -- Set text color
UserRequestInput.BackgroundColor3 = Color3.fromRGB(241, 244, 227)  -- Set background color
UserRequestInput.Font = Enum.Font.SourceSansSemibold  -- Set font
UserRequestInput.MultiLine = true  -- Allow multiple lines
UserRequestInput.TextWrapped = true  -- Enable text wrapping
UserRequestInput.TextSize = 14  -- Set text size
UserRequestInput.ClearTextOnFocus = false  -- Don't clear text when focused
UserRequestInput.Parent = ScrollingFrame  -- Set parent to the scrolling frame

local TextBoxCorner = Instance.new("UICorner")  -- Create rounded corners for the user input textbox
TextBoxCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
TextBoxCorner.Parent = UserRequestInput  -- Set parent to the user input textbox

local TextBoxPadding = Instance.new("UIPadding")  -- Create padding for the user input textbox
TextBoxPadding.PaddingLeft = UDim.new(0, 8)  -- Set left padding
TextBoxPadding.PaddingRight = UDim.new(0, 8)  -- Set right padding
TextBoxPadding.PaddingTop = UDim.new(0, 8)  -- Set top padding
TextBoxPadding.PaddingBottom = UDim.new(0, 8)  -- Set bottom padding
TextBoxPadding.Parent = UserRequestInput  -- Set parent to the user input textbox

local TextSizeConstraint = Instance.new("UITextSizeConstraint")  -- Create text size constraint for the user input textbox
TextSizeConstraint.MaxTextSize = 14  -- Set maximum text size
TextSizeConstraint.MinTextSize = 10  -- Set minimum text size
TextSizeConstraint.Parent = UserRequestInput  -- Set parent to the user input textbox

-- Create Send Button
local SendButton = Instance.new("TextButton")  -- Create button to send update request
SendButton.Size = UDim2.new(0.3, 0, 0.15, 0)  -- Set button size
SendButton.Position = UDim2.new(0.35, 0, 0.7, 0)  -- Set button position
SendButton.Text = "Update Code"  -- Set button text
SendButton.Font = Enum.Font.SourceSansBold  -- Set font
SendButton.TextSize = 16  -- Set text size
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Set text color
SendButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)  -- Set background color
SendButton.Parent = Frame  -- Set parent to the main frame
SendButton.Visible = false  -- Initially hidden

local ButtonCorner = Instance.new("UICorner")  -- Create rounded corners for the send button
ButtonCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
ButtonCorner.Parent = SendButton  -- Set parent to the send button

-- Create Response Text area
local ResponseText = Instance.new("TextLabel")  -- Create label for response text
ResponseText.Size = UDim2.new(0.9, 0, 0.1, 0)  -- Set label size
ResponseText.Position = UDim2.new(0.05, 0, 0.89, 0)  -- Set label position
ResponseText.BackgroundTransparency = 1  -- Make background transparent
ResponseText.Text = ""  -- Initially empty
ResponseText.TextColor3 = Color3.fromRGB(66, 84, 102)  -- Set text color
ResponseText.Font = Enum.Font.SourceSansSemibold  -- Set font
ResponseText.TextSize = 14  -- Set text size
ResponseText.TextWrapped = true  -- Enable text wrapping
ResponseText.TextXAlignment = Enum.TextXAlignment.Center  -- Center-align text horizontally
ResponseText.Parent = Frame  -- Set parent to the main frame

-- Create Undo Button
undoButton = Instance.new("TextButton")  -- Create button to undo changes
undoButton.Size = UDim2.new(0.3, 0, 0.1, 0)  -- Set button size
undoButton.Position = UDim2.new(0.68, 0, 0.88, 0)  -- Set button position
undoButton.Text = "Undo Changes"  -- Set button text
undoButton.Font = Enum.Font.SourceSansBold  -- Set font
undoButton.TextSize = 16  -- Set text size
undoButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Set text color
undoButton.BackgroundColor3 = Color3.fromRGB(234, 76, 137)  -- Set background color
undoButton.Parent = Frame  -- Set parent to the main frame
undoButton.Visible = false  -- Initially hidden

local UndoButtonCorner = Instance.new("UICorner")  -- Create rounded corners for the undo button
UndoButtonCorner.CornerRadius = UDim.new(0, 4)  -- Set corner radius
UndoButtonCorner.Parent = undoButton  -- Set parent to the undo button

-- Function to update ScrollingFrame size based on text content
local function updateScrollingFrame()
	local textBounds = UserRequestInput.TextBounds  -- Get the bounds of the text
	local frameHeight = ScrollingFrame.AbsoluteSize.Y  -- Get the height of the scrolling frame
	UserRequestInput.Size = UDim2.new(1, -12, 0, math.max(textBounds.Y, frameHeight))  -- Adjust input box size
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(textBounds.Y, frameHeight))  -- Adjust canvas size
end

-- Connect the update function to relevant events
UserRequestInput:GetPropertyChangedSignal("Text"):Connect(updateScrollingFrame)
UserRequestInput:GetPropertyChangedSignal("TextBounds"):Connect(updateScrollingFrame)

-- Double-click to clear text functionality
local lastClickTime = 0
UserRequestInput.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local currentTime = tick()
		if currentTime - lastClickTime < 1 then  -- If double-clicked (less than 1 second between clicks)
			UserRequestInput.Text = ""  -- Clear the text
		end
		lastClickTime = currentTime
	end
end)

-- Create Dropdown Options
local options = {"OpenAI", "Anthropic", "Google"}  -- List of API providers
for i, option in ipairs(options) do
	local OptionButton = Instance.new("TextButton")  -- Create button for each option
	OptionButton.Size = UDim2.new(1, 0, 0.33, 0)  -- Set button size
	OptionButton.Position = UDim2.new(0, 0, (i-1) * 0.33, 0)  -- Set button position
	OptionButton.Text = option  -- Set button text to the option name
	OptionButton.Font = Enum.Font.SourceSans  -- Set font
	OptionButton.TextSize = 14  -- Set text size
	OptionButton.TextColor3 = Color3.fromRGB(0, 0, 0)  -- Set text color to black
	OptionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- Set background color to white
	OptionButton.Parent = DropdownMenu  -- Set parent to the dropdown menu
	OptionButton.ZIndex = 11  -- Ensure it appears on top of other elements

	OptionButton.MouseButton1Click:Connect(function()
		selectedAPIProvider = option  -- Set the selected API provider
		APIProviderDropdown.Text = option  -- Update dropdown button text
		DropdownMenu.Visible = false  -- Hide the dropdown menu
		APIKeyInput.Visible = true  -- Show the API key input field
		APIKeyInput.Text = apiKey or "Enter API Key..."  -- Set default text for API key input
		UseAPIKeyButton.Visible = true  -- Show the Use API Key button
		ScrollingFrame.Visible = false  -- Hide the scrolling frame
		SendButton.Visible = false  -- Hide the send button
	end)
end

-- Toggle Dropdown Menu
APIProviderDropdown.MouseButton1Click:Connect(function()
	DropdownMenu.Visible = not DropdownMenu.Visible  -- Toggle visibility of dropdown menu
	if DropdownMenu.Visible then
		DropdownMenu.ZIndex = 10  -- Ensure dropdown menu appears on top
		ScrollingFrame.Visible = true  -- Show the scrolling frame
		SendButton.Visible = true  -- Show the send button
	end
end)

-- Use API Key Button Click Handler
UseAPIKeyButton.MouseButton1Click:Connect(function()
	apiKey = APIKeyInput.Text  -- Store the entered API key
	APIKeyInput.Visible = false  -- Hide the API key input field
	UseAPIKeyButton.Visible = false  -- Hide the Use API Key button
	ScrollingFrame.Visible = true  -- Show the scrolling frame
	SendButton.Visible = true  -- Show the send button
end)

-- Function to create an undo point
local function createUndoPoint(description)
	ChangeHistoryService:SetWaypoint(description)  -- Set a waypoint in the undo history
end

-- Function to create the API prompt (generic for all providers)
local function createAPIPrompt(codebase, userRequest)
	-- Construct and return the prompt string for the API request
	return [[
		Please analyze the following codebase and make the requested changes. 
		Respond with a JSON structure containing the original code snippet and the updated version for each change that was requested.

		User Request: ]] .. userRequest .. [[  

		Codebase:
		]] .. codebase .. [[ 

		Please provide your response in the following JSON format:
		{
		    "changes": [
		        {
		            "previousCode": "Exact snippet of code to be replaced",
		            "newCode": "Updated version of the code snippet",
		            "explanation": "Brief explanation of the changes made"
		        }
		    ]
		}

		Only include the JSON in your response, without any additional text or formatting.
	]]
end

-- Function to serialize scripts from a specific service
local function serializeScriptsFromService(service)
	-- Initialize an empty table to store serialized script data
	local scriptsData = {}

	-- Iterate through all descendants of the given service
	for _, script in ipairs(service:GetDescendants()) do
		-- Check if the descendant is a Script, LocalScript, or ModuleScript
		if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
			-- Add the script's data to the scriptsData table
			table.insert(scriptsData, {
				Name = script.Name,  -- Store the script's name
				ClassName = script.ClassName,  -- Store the script's class name (Script, LocalScript, or ModuleScript)
				ParentName = script.Parent and script.Parent.Name or "None",  -- Store the parent's name, or "None" if there's no parent
				Source = script.Source  -- Store the script's source code
			})
		end
	end

	-- Print a log message with the number of scripts serialized and the service name
	print("Serialized " .. #scriptsData .. " scripts from " .. service.Name)

	-- Return the table containing all serialized script data
	return scriptsData
end

-- Function to serialize all scripts and create backups
local function serializeAllScripts()
	-- Initialize an empty table to store all serialized script data
	local allScriptsData = {}

	-- Clear previous backups
	scriptBackups = {}

	-- Define the services to check for scripts
	local servicesToCheck = {game.ServerScriptService, game.ReplicatedStorage, game.StarterGui}

	-- Iterate through each service in the servicesToCheck list
	for _, serviceBeingChecked in pairs(servicesToCheck) do
		-- Iterate through all descendants of the current service
		for _, script in ipairs(serviceBeingChecked:GetDescendants()) do
			-- Check if the descendant is a Script, LocalScript, or ModuleScript
			if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
				-- Create a table to store the current script's data
				local scriptData = {
					Name = script.Name,  -- Store the script's name
					ClassName = script.ClassName,  -- Store the script's class name
					ParentName = script.Parent and script.Parent.Name or "None",  -- Store the parent's name, or "None" if there's no parent
					Source = script.Source  -- Store the script's source code
				}

				-- Add the script data to the allScriptsData table
				table.insert(allScriptsData, scriptData)

				-- Create a backup of the script by storing its source code
				scriptBackups[script] = script.Source
			end
		end
	end

	-- Print a log message with the number of scripts serialized and backed up, and the number of services checked
	print("Serialized and backed up " .. #allScriptsData .. " scripts from " .. #servicesToCheck .. " services")

	-- Return the table containing all serialized script data
	return allScriptsData
end

-- Function to revert changes made to scripts
local function revertChanges()
	-- Iterate through each script and its original source in the scriptBackups table
	for script, originalSource in pairs(scriptBackups) do
		-- Check if the script is still a valid Script, LocalScript, or ModuleScript
		if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
			-- Restore the original source code to the script
			script.Source = originalSource

			-- Use ScriptEditorService to update the script's source asynchronously
			ScriptEditorService:UpdateSourceAsync(script, function()
				return originalSource
			end)
		end
	end

	-- Update the ResponseText to indicate that changes have been reverted
	ResponseText.Text = "Changes reverted"

	-- Set the text color to green to indicate success
	ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)

	-- Hide the undo button as changes have been reverted
	undoButton.Visible = false
end

-- Connect the revertChanges function to the undo button's click event
undoButton.MouseButton1Click:Connect(revertChanges)

-- Function to send request to the selected API
local function sendToAPI(scriptData, userRequest)
	-- Create the API prompt using the scriptData and userRequest
	local prompt = createAPIPrompt(HttpService:JSONEncode(scriptData), userRequest)

	-- Initialize variables for API request
	local url, headers, body

	-- Log that we're about to send to the API
	print("Going to send to api")

	-- Configure the API request based on the selected provider
	if selectedAPIProvider == "OpenAI" then
		-- OpenAI API configuration
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
		-- Anthropic API configuration
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
		-- Google API configuration
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
		-- Append API key to URL for Google's API
		url = url .. "?key=" .. apiKey
		print("URL we're sending to google is: ", url)
	else
		-- Return an error if an invalid API provider is selected
		return "Error: Invalid API provider selected"
	end

	-- Make the API request
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = headers,
			Body = body
		})
	end)

	-- Process the API response
	if success then
		if response.Success then
			-- Parse the response based on the selected API provider
			local responseData = HttpService:JSONDecode(response.Body)
			if selectedAPIProvider == "OpenAI" then
				return responseData.choices[1].message.content
			elseif selectedAPIProvider == "Anthropic" then
				return responseData.content[1].text
			elseif selectedAPIProvider == "Google" then
				return responseData.candidates[1].content.parts[1].text
			end
		else
			-- Log the full response if the request was not successful
			print(response)
			return "Error: API request failed with status "
		end
	else
		-- Return an error message if the request failed
		return "Error: " .. tostring(response)
	end
end

-- Function to apply code changes suggested by API
local function applyCodeChanges(apiResponse)
	-- Log the start of the function
	print("Applying code changes function started")

	-- Parse the changes from the API response
	local changes = HttpService:JSONDecode(apiResponse).changes

	-- Log the content of changes to be applied
	print("Content of changes to apply in applyCodeChanges function are: ", changes)

	-- Iterate through each change suggested by the API
	for _, change in ipairs(changes) do
		local previousCode = change.previousCode
		local newCode = change.newCode

		-- Log the previous and new code for each change
		print("Previous code is: ", previousCode)
		print("New Code is: ", newCode)

		-- Iterate through relevant services to find and update scripts
		for _, service in ipairs({game.ServerScriptService, game.ReplicatedStorage, game.StarterGui}) do
			for _, script in ipairs(service:GetDescendants()) do
				-- Check if the descendant is a Script, LocalScript, or ModuleScript
				if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
					local source = script.Source
					-- Find the exact location of the code to be replaced
					local startIndex, endIndex = string.find(source, previousCode, 1, true)

					if startIndex then
						-- Log that matching code was found
						print("Matching code found in Script: ", script.Name)

						-- Comment out the previous code
						local commentedCode = string.gsub(previousCode, "([^\r\n]+)", "--[[ %1 ]]")

						-- Construct the updated source with commented old code and new code
						local updatedSource = string.sub(source, 1, startIndex - 1) .. commentedCode .. "\n" .. newCode .. "\n" .. string.sub(source, endIndex + 1)

						-- Update the script's source
						script.Source = updatedSource

						-- Use ScriptEditorService to update the script's source asynchronously
						ScriptEditorService:UpdateSourceAsync(script, function(previousCode)
							return updatedSource
						end)

						-- Open the updated script in the editor
						plugin:OpenScript(script, startIndex)

						-- Log the details of the updated script
						print("Updated script: " .. script.Name .. " in Service: " .. service.Name .. " \n \n \n \n With updated source of:" .. updatedSource)
						break
					end 
				end
			end
		end
	end
end

-- Function to update code based on user request
local function updateCode()
	-- Get the user's request from the input field
	local userRequest = UserRequestInput.Text

	-- Serialize and backup all scripts
	local serializedScripts = serializeAllScripts()

	-- Send request to API with serialized scripts and user request
	local apiResponse = sendToAPI(serializedScripts, userRequest)

	-- Check if the API response indicates an error
	if apiResponse:sub(1, 5) == "Error" then
		-- Display error message in the ResponseText
		ResponseText.Text = apiResponse
		-- Set text color to red to indicate error
		ResponseText.TextColor3 = Color3.fromRGB(234, 76, 137)
	else
		-- Log that we're about to apply changes
		print("Going to apply changes: ", apiResponse)

		-- Apply the changes suggested by the API
		applyCodeChanges(apiResponse)

		-- Display success message in the ResponseText
		ResponseText.Text = "Success"

		-- Set text color to green to indicate success
		ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)

		-- Show the undo button
		undoButton.Visible = true
	end

	-- Log completion of updateCode function
	print("Completed updateCode function")
end

-- Connect the updateCode function to the send button's click event
SendButton.MouseButton1Click:Connect(updateCode)

-- Create a toolbar button to toggle the widget
local toolbar = plugin:CreateToolbar("Code Updater")
local toggleButton = toolbar:CreateButton("ToggleUpdater", "Toggle Code Updater", "")

-- Toggle button handler
toggleButton.Click:Connect(function()
	-- Toggle the visibility of the plugin GUI
	pluginGui.Enabled = not pluginGui.Enabled
end)

-- Initialize the plugin
local function init()
	-- Hide UI elements initially
	ScrollingFrame.Visible = false
	SendButton.Visible = false
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
end

-- Call the initialization function
init()
