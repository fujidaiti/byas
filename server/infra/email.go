package infra

type EmailSender = func(from, to, body string) error

func SendEmail(from, to, body string) error {
	// TODO: Send an email using Resend
	return nil
}
