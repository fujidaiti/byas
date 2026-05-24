package worker

import (
	"context"
	"fmt"
	"sync"
	"time"
)

type Job interface {
	Do(ctx context.Context) error
	Timeout() time.Duration
}

type Pool struct {
	jobs chan Job
	wg   sync.WaitGroup
}

func (p *Pool) Start(ctx context.Context, workerNum int) {
	if p.jobs != nil {
		panic("Cannot restart the same worker pool.")
	}
	if workerNum <= 0 {
		panic(fmt.Sprintf("A positive number for worker count is expected, but got %d", workerNum))
	}
	p.jobs = make(chan Job)
	for range workerNum {
		p.wg.Add(1)
		go p.worker(ctx)
	}
}

func (p *Pool) worker(ctx context.Context) {
	defer p.wg.Done()
	for {
		select {
		case <-ctx.Done():
			return

		case job, ok := <-p.jobs:
			if !ok {
				return
			}
			process(ctx, job)
		}
	}
}

func process(ctx context.Context, job Job) {
	t := job.Timeout()
	if t > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, t)
		defer cancel()
	}
	err := job.Do(ctx)
	if err != nil {
		fmt.Println(err)
	}
}

// TODO: Pass a context to set a timeout
func (p *Pool) Shutdown() {
	close(p.jobs)
	p.wg.Wait()
}

func (p *Pool) Push(ctx context.Context, job Job) error {
	select {
	case <-ctx.Done():
		return ctx.Err()

	case p.jobs <- job:
		return nil
	}
}
