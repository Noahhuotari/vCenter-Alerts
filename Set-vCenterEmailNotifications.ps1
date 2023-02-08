
<#	
	.NOTES
	===========================================================================
	 Created on:   	02/08/2023
	 Created by:    Noah Huotari
	 Organization: 	HBS
	 Filename:     	Set-vCenterEmailNotifications.ps1
	===========================================================================
	.DESCRIPTION
		Set vCenter email alerts
#>

#Set variables here
################################################################################################
$alarmfile = import-csv "Enter path to CSV file"                        
$AlertEmailRecipients = @("nhuotari@hbs.net")             
$SMTPServer = "SMTP Serever FQDN here"                                           
$SMTPPort = "25"                                                              
$SMTPSendingAddress = "vcenter-alerts@domain.com"                                      
################################################################################################




#Prompt for vCenter info
$vcenter = Read-Host -Prompt 'Input your vCenter hostname/IP Address'
$credential=Get-Credential

#Check if connected to any vCenter servers and disconnect if so

If ($global:DefaultVIServers.Count -ne 0) 
{
	Disconnect-VIServer -Server *  -Confirm:$false
}

#Import PowerCLI module
import-module -name VMware.PowerCLI

#Connect to vCenter using variables from above.
Connect-viserver $vcenter -Credential $credential
 
#----These Alarms will be disabled and not send any email messages at all ----
$DisabledAlarms = $alarmfile | where-object priority -EQ "Disabled"
 
#----These Alarms will send a single email message and not repeat ----
$LowPriorityAlarms = $alarmfile | where-object priority -EQ "low"
 
#----These Alarms will repeat every 24 hours----
$MediumPriorityAlarms = $alarmfile | where-object priority -EQ "medium"
 
#----These Alarms will repeat every 4 hours----
$HighPriorityAlarms = $alarmfile | where-object priority -EQ "high"
 
#Set SMTP settings on vCenter
Get-AdvancedSetting -Entity $vcenter -Name mail.smtp.server | Set-AdvancedSetting -Value $SMTPServer -Confirm:$false
Get-AdvancedSetting -Entity $vcenter -Name mail.smtp.port | Set-AdvancedSetting -Value $SMTPPort -Confirm:$false
Get-AdvancedSetting -Entity $vcenter -Name mail.sender | Set-AdvancedSetting -Value $SMTPSendingAddress -Confirm:$false
 
#---Disable Alarm Action for Disabled Alarms---
Foreach ($DisabledAlarm in $DisabledAlarms) {
Get-AlarmDefinition -Name $DisabledAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
}
 
#---Set Alarm Action for Low Priority Alarms---
Foreach ($LowPriorityAlarm in $LowPriorityAlarms) {
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
Get-AlarmDefinition -Name $LowPriorityAlarm.name | New-AlarmAction -Email -To @($AlertEmailRecipients)
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
#Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" # This ActionTrigger is enabled by default.
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
 
#---Set Alarm Action for Medium Priority Alarms---
Foreach ($MediumPriorityAlarm in $MediumPriorityAlarms) {
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Set-AlarmDefinition -ActionRepeatMinutes (60 * 24) # 24 Hours
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | New-AlarmAction -Email -To @($AlertEmailRecipients)
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
 
#---Set Alarm Action for High Priority Alarms---
Foreach ($HighPriorityAlarm in $HighPriorityAlarms) {
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
Get-AlarmDefinition -name $HighPriorityAlarm.name | Set-AlarmDefinition -ActionRepeatMinutes (60 * 4) # 4 hours
Get-AlarmDefinition -Name $HighPriorityAlarm.name | New-AlarmAction -Email -To @($AlertEmailRecipients)
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
