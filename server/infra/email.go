package infra

// TODO: Move these types and functions to infra/email package
type Draft struct {
	To      string
	Subject string
	Body    string
}

type EmailSender = func(d Draft) error

func SendEmail(d Draft) error {
	// TODO: Send an email using Resend
	return nil
}
