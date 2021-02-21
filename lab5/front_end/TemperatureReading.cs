using System;

namespace TemperatureLogger
{
    struct TemperatureReading
    {
        public string Timestamp;
        public string Temperature;

        public TemperatureReading(String timestamp = "", String temperature = "")
        {
            this.Timestamp = timestamp;
            this.Temperature = temperature;
        }

        public override string ToString()
        {
            DateTime stamp;
            DateTime.TryParse(Timestamp, out stamp);
            return $"on {stamp}, we got {Temperature}";
        }
    }
}