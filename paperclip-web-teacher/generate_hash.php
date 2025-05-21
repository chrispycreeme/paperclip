    <?php
    // Replace 'your_teacher_password' with the actual password you want to use
    $password_to_hash = '123';
    $hashed_password = password_hash($password_to_hash, PASSWORD_DEFAULT);
    echo "Password: " . $password_to_hash . "<br>";
    echo "Hashed Password: " . $hashed_password . "<br><br>";

    $password_to_hash_2 = '123';
    $hashed_password_2 = password_hash($password_to_hash_2, PASSWORD_DEFAULT);
    echo "Password: " . $password_to_hash_2 . "<br>";
    echo "Hashed Password: " . $hashed_password_2 . "<br>";
    ?>