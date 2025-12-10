# Offline Vaccine Calendars

All vaccination calendars now ship with the app and never require downloading from the internet. The data lives inside the `Resources/` folder and is loaded directly from the bundle, so country selection works fully offline.

## Supported Countries

- USA  
- China  
- Russia  
- Germany  
- France  
- Italy  
- Brazil  
- Argentina  
- Mexico  
- India  
- Turkey  
- Japan  
- Norway  
- Egypt  
- Philippines  

## JSON Format

Each file follows the same schema:

```json
{
  "country_code": {
    "mandatory": [
      {
        "id": "unique_vaccine_id",
        "name": "Vaccine Name",
        "disease": "Disease Name",
        "ageInMonths": 0,
        "ageDescription": "Birth",
        "isMandatory": true,
        "description": "Vaccine description",
        "notes": "Additional notes"
      }
    ],
    "recommended": [
      // Similar structure for recommended vaccines
    ]
  }
}
```

## Data Storage

- `vaccines_usa.json` and `vaccines_china.json` keep the dedicated US and China calendars
- Every other country is stored inside the shared `vaccines_data.json`
- Adding a new country only requires adding a new entry keyed by its lowercase code

## Error Handling

- If a file is missing or corrupted the user sees a clear error message
- When loading fails, only the user-defined vaccines are shown so the UI stays functional