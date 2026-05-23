package worker

import (
	"sync"
)

type Job interface {
	Process()
}

type Pool struct {
	workerNum int
	jobs      chan Job
	wg        sync.WaitGroup
}

func NewPool(workerNum int) *Pool {
	p := Pool{workerNum: workerNum, jobs: make(chan Job)}
	for range workerNum {
		p.wg.Add(1)
		go worker(p.jobs, &p.wg)
	}
	return &p
}

func worker(c <-chan Job, wg *sync.WaitGroup) {
	defer wg.Done()
	for {
		job, ok := <-c
		if !ok {
			return
		}
		job.Process()
	}
}

func (p *Pool) Shutdown() {
	close(p.jobs)
	p.wg.Wait()
}

func (p *Pool) Push(job Job) {
	p.jobs <- job
}
