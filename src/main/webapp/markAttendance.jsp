
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Mark Attendance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            text-align: center;
        }
        .box {
            background: white;
            max-width: 400px;
            margin: 40px auto;
            padding: 25px;
            border-radius: 10px;
        }
        input, select, button {
            box-sizing: border-box;
            width: 100%;
            padding: 11px;
            margin: 8px 0;
        }
        button {
            background: #2563eb;
            color: white;
            border: none;
            cursor: pointer;
        }
        a { color: #2563eb; }
    </style>
</head>
<body>
    <div class="box">
        <h1>Mark Attendance</h1>

        <form action="markAttendance" method="post">
            <input type="text" name="rollNo"
                   placeholder="Student Roll Number" required>

            <input type="date" name="date" required>

            <select name="status" required>
                <option value="Present">Present</option>
                <option value="Absent">Absent</option>
            </select>

            <button type="submit">Save Attendance</button>
        </form>

        <p><a href="index.jsp">Back to Home</a></p>
    </div>
</body>
</html>
