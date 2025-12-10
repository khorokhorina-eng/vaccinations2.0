# Offline Vaccine Calendars

Все календари прививок теперь поставляются вместе с приложением и не требуют загрузки из интернета. Данные находятся в JSON-файлах в каталоге `Resources/` и подгружаются напрямую из бандла, поэтому выбор страны работает полностью офлайн.

## Поддерживаемые страны

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

## Формат JSON

Каждый файл соответствует единому формату:

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

## Хранение данных

- Для США и Китая используются файлы `vaccines_usa.json` и `vaccines_china.json`
- Все остальные страны хранятся в общем файле `vaccines_data.json`
- Формат позволяет легко добавлять новые страны, достаточно внести запись с соответствующим `country_code`

## Обработка ошибок

- Если файл не найден или JSON поврежден, пользователь увидит понятное сообщение об ошибке
- При ошибке загрузки показываются только пользовательские прививки, поэтому интерфейс остается рабочим даже при проблемах с данными