using Microsoft.AspNetCore.Mvc;
using MySql.Data.MySqlClient;
using System.Data;
using WebApplication1.Model;

namespace WebApplication1.Controllers
{
    [ApiController]
    [Route("v1/events")]
    public class EventsController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public EventsController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpPost("sms")]
        public async Task<IActionResult> PostSmsEvent([FromBody] Sms request)
        {
            if (request == null)
                return BadRequest("Request body is empty");

            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using var connection = new MySqlConnection(connectionString);
                await connection.OpenAsync();

                using var command = new MySqlCommand("sp_insert_sms_event", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("p_event_type", request.EventType);
                command.Parameters.AddWithValue("p_sender", request.Sender);
                command.Parameters.AddWithValue("p_message", request.Message);
                command.Parameters.AddWithValue("p_timestamp", request.Timestamp);
                command.Parameters.AddWithValue("p_is_transactional", request.IsTransactional);

                await command.ExecuteNonQueryAsync();

                return Ok(new { message = "SMS event saved successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        [HttpPost("call")]
        public async Task<IActionResult> PostCallLog([FromBody] Addlog request)
        {
            if (request == null)
                return BadRequest("Request body is empty");

            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using var connection = new MySqlConnection(connectionString);
                await connection.OpenAsync();

                using var command = new MySqlCommand("sp_insert_call_log", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("p_event_type", request.EventType);
                command.Parameters.AddWithValue("p_call_type", request.CallType);
                command.Parameters.AddWithValue("p_phone_number", request.PhoneNumber);
                command.Parameters.AddWithValue("p_duration", request.Duration);
                command.Parameters.AddWithValue("p_timestamp", request.Timestamp);

                await command.ExecuteNonQueryAsync();

                return Ok(new { message = "Call log saved successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
        [HttpPost("batch")]
        public async Task<IActionResult> PostBatch([FromBody] BatchRequest request)
        {
            if (request?.Events == null)
                return BadRequest("No events in request");

            var connectionString = _configuration.GetConnectionString("DefaultConnection");

            using var connection = new MySqlConnection(connectionString);
            await connection.OpenAsync();

            var transaction = await connection.BeginTransactionAsync();

            try
            {
                foreach (var evt in request.Events)
                {
                    if (evt.EventType == "sms")
                    {
                        using var command = new MySqlCommand("sp_insert_sms_event", connection, transaction);
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("p_event_type", evt.EventType);
                        command.Parameters.AddWithValue("p_sender", evt.Sender);
                        command.Parameters.AddWithValue("p_message", evt.Message);
                        command.Parameters.AddWithValue("p_timestamp", evt.Timestamp);
                        command.Parameters.AddWithValue("p_is_transactional", evt.IsTransactional);
                        await command.ExecuteNonQueryAsync();
                    }
                    else if (evt.EventType == "call")
                    {
                        using var command = new MySqlCommand("sp_insert_call_log", connection, transaction);
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("p_event_type", evt.EventType);
                        command.Parameters.AddWithValue("p_call_type", evt.CallType);
                        command.Parameters.AddWithValue("p_phone_number", evt.PhoneNumber);
                        command.Parameters.AddWithValue("p_duration", evt.Duration);
                        command.Parameters.AddWithValue("p_timestamp", evt.Timestamp);
                        await command.ExecuteNonQueryAsync();
                    }
                }

                await transaction.CommitAsync();
                return Ok(new { message = $"Processed {request.Events.Count} events" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { error = ex.Message });
            }
        }

        public class BatchRequest
        {
            public List<BatchEvent> Events { get; set; }
        }

        public class BatchEvent
        {
            public string EventType { get; set; }
            public string Sender { get; set; } = string.Empty; // Default value
            public string Message { get; set; } = string.Empty; // Default value
            public DateTime Timestamp { get; set; }
            public bool IsTransactional { get; set; }
            public string CallType { get; set; } = "unknown"; // Default value
            public string PhoneNumber { get; set; } = "Unknown"; // Default value
            public int Duration { get; set; }
        }
    }
}