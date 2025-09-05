# Sample Remote Calendar URLs

В реальном приложении календари прививок для дополнительных стран будут загружаться с удаленного сервера.

## Примеры URL для загрузки:

### Европа
- Germany: https://api.vaccine-calendars.org/v1/countries/germany.json
- France: https://api.vaccine-calendars.org/v1/countries/france.json  
- Italy: https://api.vaccine-calendars.org/v1/countries/italy.json

### Россия
- Russia: https://api.vaccine-calendars.org/v1/countries/russia.json

### Латинская Америка
- Brazil: https://api.vaccine-calendars.org/v1/countries/brazil.json
- Argentina: https://api.vaccine-calendars.org/v1/countries/argentina.json
- Mexico: https://api.vaccine-calendars.org/v1/countries/mexico.json

## Формат JSON

Все календари должны следовать единому формату:

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

## Кеширование

- Загруженные календари сохраняются локально на 30 дней
- При отсутствии интернета используется кешированная версия
- Пользователь может принудительно обновить календарь

## Обработка ошибок

- При отсутствии интернета показывается сообщение об ошибке
- Если календарь уже был загружен ранее, используется кешированная версия
- Встроенные календари (США, Китай) всегда доступны офлайн