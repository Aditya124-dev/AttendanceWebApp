
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Add Student</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #eef2f7;
            margin: 0;
            padding: 30px;
        }
        .form-box {
            max-width: 420px;
            margin: 30px auto;
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 3px 12px #cccccc;
        }
        h2 { text-align: center; color: #183a70; }
        label { display: block; margin-top: 14px; }
        input {
            width: 100%;
            padding: 10px;
            margin-top: 5px;
            box-sizing: border-box;
        }
        button {
            margin-top: 22px;
            width: 100%;
            padding: 12px;
            background: #2563eb;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .home { text-align: center; margin-top: 18px; }
    </style>
</head>
<body>
    <div class="form-box">
        <h2>Add Student</h2>

        <form action="addStudent" method="post">
            <label>Roll Number</label>
            <input type="text" name="rollNo" required>

            <label>Student Name</label>
            <input type="text" name="name" required>

            <label>Course</label>
            <input type="text" name="course" required>

            <label>Semester</label>
            <input type="number" name="semester" min="1" required>

            <button type="submit">Add Student</button>
        </form>

        <div class="home">
            <a href="index.jsp">Back to Home</a>
        </div>
    </div>
</body>
</html>