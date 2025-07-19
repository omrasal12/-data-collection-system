namespace WebApplication1.Model
{
    public class Addlog
    {
        public string EventType { get; set; }         // "call"
        public string CallType { get; set; }          // "incoming", "outgoing", "missed"
        public string PhoneNumber { get; set; }
        public int Duration { get; set; }             // in seconds
        public DateTime Timestamp { get; set; }
    }
}
