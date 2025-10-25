exports.login = async (req, res) => {
  console.log("Login function called");
  
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).send({ 
      success: false,
      message: "Email and password are required" 
    });
  }

  try {
    const user = await req.db.User.findOne({
      where: { email: email },
      raw: true,
    });

    if (!user) {
      return res.status(401).send({ 
        success: false,
        message: "Invalid email or password" 
      });
    }

 

    if (user.password !== password) {
      return res.status(401).send({ 
        success: false,
        message: "Invalid email or password" 
      });
    }

    res.status(200).send({
      success: true,
      message: "Login successful",
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      }
    });

  } catch (err) {
    console.error("Login error:", err);
    res.status(500).send({ 
      success: false,
      message: "Internal server error" 
    });
  }
};