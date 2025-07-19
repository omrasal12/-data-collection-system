namespace WebApplication1.Model
{
    public class Sms
    {
        public string EventType { get; set; }           // "sms"
        public string Sender { get; set; }
        public string Message { get; set; }
        public DateTime Timestamp { get; set; }
        public bool IsTransactional { get; set; }
    }
}
